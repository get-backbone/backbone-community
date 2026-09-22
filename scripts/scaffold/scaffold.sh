#!/usr/bin/env bash
set -euo pipefail

# scaffold.sh
# Type: executable
# Scaffolds a new domain service from services/template-service and wires platform touchpoints.
# Usage: task dev:scaffold -- <service-name> [--with-rds]
#        ./scripts/scaffold/scaffold.sh <service-name> [--with-rds]

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
# shellcheck source=scripts/scaffold/service-name.sh
source "${SCRIPT_DIR}/service-name.sh"

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli gum
    require_cli jq
    require_cli rsync
}

usage() {
    cat << EOF
Usage:
    $(basename "$0") <service-name> [--with-rds]

Examples:
    $(basename "$0") quote-engine
    $(basename "$0") search-service --with-rds

Name is used verbatim as the module directory and Maven artifactId (kebab-case).
template-service/src includes RDS persistence; omit --with-rds to strip it from the new module.
EOF
}

# Remove RDS persistence from a copied module so the result is stateless.
# Persistence source of truth remains in services/template-service/src.
strip_rds_for_stateless() {
    local dest_dir="$1"
    local java_root="${dest_dir}/src/main/java/io/backbone/services/template"
    local test_root="${dest_dir}/src/test/java/io/backbone/services/template"
    local parent_version

    log_info "Stripping RDS persistence (stateless scaffold)"

    parent_version="$(
        awk '/<parent>/,/<\/parent>/' "${dest_dir}/pom.xml" |
            sed -n 's/^[[:space:]]*<version>\([^<]*\)<\/version>.*/\1/p' |
            head -1
    )"
    if [[ -z "$parent_version" ]]; then
        log_error "Could not read parent version from ${dest_dir}/pom.xml"
        exit 1
    fi

    rm -rf \
        "${java_root}/infrastructure/persistence" \
        "${dest_dir}/src/main/resources/db"
    rm -f \
        "${java_root}/infrastructure/TemplateEventMapper.java" \
        "${java_root}/infrastructure/TemplateServiceHealthChecks.java"

    cat > "${dest_dir}/pom.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>io.backbone.core</groupId>
        <artifactId>services</artifactId>
        <version>${parent_version}</version>
    </parent>

    <artifactId>template-service</artifactId>

</project>
EOF

    cat > "${dest_dir}/src/main/resources/application.properties" << 'EOF'
quarkus.application.name=template-service
quarkus.http.port=${TEMPLATE_SERVICE_PORT:8080}
# Class-loading is read before normal config (Quarkus docs): must be in application.properties.
quarkus.class-loading.parent-first-artifacts=io.backbone.core:sdk-bundle
quarkus.config.locations=quarkus.properties,platform-config.yml,aws.properties,throttle.properties,otel.properties,logging.properties,metrics.properties,cache.properties,redis.properties

# REST service client configurations (AuthServiceClient for S2S tokens)
quarkus.rest-client.AuthServiceClient.url=${BACKBONE_INTERNAL_ALB_URL:http://localhost:${AUTH_SERVICE_PORT}}

# No aws-api EventBridgeClient on developer/client scaffolds; build-gates EventBridge dispatcher.
backbone.audit.enabled=false
EOF

    cat > "${java_root}/domain/TemplateService.java" << 'EOF'
package io.backbone.services.template.domain;

import io.backbone.core.audit.api.domain.AuditEvent;
import io.backbone.core.audit.api.domain.EventSeverity;
import io.backbone.core.audit.api.domain.EventType;
import io.backbonehq.kit.logging.api.LogMethodEntry;
import io.backbonehq.kit.metrics.api.domain.ServiceMetrics;
import io.backbone.services.template.domain.dto.TemplateEventRequest;
import io.backbone.services.template.domain.dto.TemplateEventResponse;
import io.backbone.services.template.infrastructure.TemplateMetricsRecorder;
import io.opentelemetry.instrumentation.annotations.WithSpan;
import jakarta.enterprise.context.ApplicationScoped;
import org.jboss.logging.Logger;

/**
 * Domain service for the template example flow.
 * Stateless: validates input and returns an accepted response (no persistence).
 */
@ApplicationScoped
public class TemplateService
{
    private static final Logger LOGGER = Logger.getLogger(TemplateService.class);

    /**
     * Processes a template example event.
     *
     * @param request the event payload
     * @return accepted response mirroring the event id
     */
    @WithSpan
    @ServiceMetrics(TemplateMetricsRecorder.class)
    @LogMethodEntry(message = "for event: %s", argPaths = {"#request#eventId"})
    @AuditEvent(message = "Template event: %s", argPaths = {"#request#eventId"}, type = EventType.DATA_ACCESS, severity = EventSeverity.INFO)
    public TemplateEventResponse processEvent(final TemplateEventRequest request)
    {
        LOGGER.debugf("Processing template event %s", request.getEventId());
        return TemplateEventResponse.accepted(request.getEventId());
    }
}
EOF

    mkdir -p "${test_root}/rest"
    cat > "${test_root}/rest/TemplateResourceIT.java" << 'EOF'
package io.backbone.services.template.rest;

import io.backbone.core.common.api.test.QuarkusLoggingTestResource;
import io.backbone.core.common.api.test.QuarkusPortsEnvTestResource;
import io.backbonehq.kit.throttle.impl.test.ThrottlingDisabledTestProfile;
import io.backbone.services.template.domain.dto.TemplateEventRequest;
import io.quarkus.test.common.QuarkusTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.TestProfile;
import io.restassured.RestAssured;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/**
 * REST API integration test for template event ingest.
 * <p>
 * Tests the HTTP layer: POST /templates/events, request validation, and status codes.
 * Stateless scaffold has no persistence assertions.
 */
@QuarkusTest
@QuarkusTestResource(QuarkusPortsEnvTestResource.class)
@QuarkusTestResource(QuarkusLoggingTestResource.class)
@TestProfile(ThrottlingDisabledTestProfile.class)
class TemplateResourceIT
{
    @Test
    void ingestEventSuccess()
    {
        final TemplateEventRequest request = TemplateEventRequest.builder()
            .eventId(UUID.randomUUID())
            .message("example event")
            .build();

        RestAssured.given()
            .contentType("application/json")
            .body(request)
            .when()
            .post("/templates/events")
            .then()
            .statusCode(201);
    }

    @Test
    void ingestEventMissingRequiredFieldReturnsBadRequest()
    {
        final TemplateEventRequest request = TemplateEventRequest.builder()
            .eventId(UUID.randomUUID())
            .message("example event")
            .build();
        request.setMessage(null);

        RestAssured.given()
            .contentType("application/json")
            .body(request)
            .when()
            .post("/templates/events")
            .then()
            .statusCode(400);
    }

    @Test
    void ingestEventEmptyBodyReturnsBadRequest()
    {
        RestAssured.given()
            .contentType("application/json")
            .body("{}")
            .when()
            .post("/templates/events")
            .then()
            .statusCode(400);
    }
}
EOF
}

find_next_service_port() {
    local ports_env="$1"
    local max_port=8104
    local line port

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// /}" ]] && continue
        if [[ "$line" =~ ^[[:space:]]*[A-Z_]+=([0-9]+)[[:space:]]*$ ]]; then
            port="${BASH_REMATCH[1]}"
            if ((port >= 8100 && port < 8500 && port > max_port)); then
                max_port=$port
            fi
        fi
    done < "$ports_env"

    echo $((max_port + 1))
}

copy_template_tree() {
    local source_dir="$1"
    local dest_dir="$2"

    mkdir -p "$dest_dir"
    rsync -a --exclude 'target/' --exclude '.git/' --exclude 'rds/' "${source_dir}/" "${dest_dir}/"
}

rename_java_paths() {
    local dest_dir="$1"
    local package_segment="$2"
    local class_prefix="$3"
    local java_root="${dest_dir}/src"
    local old_pkg_dir new_pkg_dir
    local file base_name new_name

    old_pkg_dir="${java_root}/main/java/io/backbone/services/template"
    new_pkg_dir="${java_root}/main/java/io/backbone/services/${package_segment}"
    if [[ -d "$old_pkg_dir" ]]; then
        mkdir -p "$(dirname "$new_pkg_dir")"
        mv "$old_pkg_dir" "$new_pkg_dir"
    fi

    old_pkg_dir="${java_root}/test/java/io/backbone/services/template"
    new_pkg_dir="${java_root}/test/java/io/backbone/services/${package_segment}"
    if [[ -d "$old_pkg_dir" ]]; then
        mkdir -p "$(dirname "$new_pkg_dir")"
        mv "$old_pkg_dir" "$new_pkg_dir"
    fi

    while IFS= read -r -d '' file; do
        base_name="$(basename "$file")"
        if [[ "$base_name" == Template* ]]; then
            new_name="${class_prefix}${base_name#Template}"
            mv "$file" "$(dirname "$file")/${new_name}"
        fi
    done < <(find "$java_root" -type f -name 'Template*.java' -print0)
}

replace_tokens_in_tree() {
    local dest_dir="$1"
    local service_name="$2"
    local package_segment="$3"
    local class_prefix="$4"
    local port_var="$5"
    local file

    while IFS= read -r -d '' file; do
        if [[ "$(uname -s)" == "Darwin" ]]; then
            sed -i '' \
                -e "s/TEMPLATE_SERVICE_PORT/${port_var}/g" \
                -e "s/template-service/${service_name}/g" \
                -e "s/io\.backbone\.services\.template/io.backbone.services.${package_segment}/g" \
                -e "s/Template/${class_prefix}/g" \
                -e "s/template/${package_segment}/g" \
                "$file"
        else
            sed -i \
                -e "s/TEMPLATE_SERVICE_PORT/${port_var}/g" \
                -e "s/template-service/${service_name}/g" \
                -e "s/io\.backbone\.services\.template/io.backbone.services.${package_segment}/g" \
                -e "s/Template/${class_prefix}/g" \
                -e "s/template/${package_segment}/g" \
                "$file"
        fi
    done < <(find "$dest_dir" -type f \( -name '*.java' -o -name '*.properties' -o -name 'pom.xml' -o -name '*.sql' \) -print0)

    # Rename Flyway files that still contain the template token (e.g. V1__create_template_events_table.sql)
    local sql_file sql_dir sql_base
    while IFS= read -r -d '' sql_file; do
        sql_dir="$(dirname "$sql_file")"
        sql_base="$(basename "$sql_file")"
        if [[ "$sql_base" == *template* ]]; then
            mv "$sql_file" "${sql_dir}/${sql_base//template/${package_segment}}"
        fi
    done < <(find "$dest_dir" -type f -name '*.sql' -print0)
}

insert_services_pom_module() {
    local pom_file="$1"
    local service_name="$2"
    local module_line="        <module>${service_name}</module>"
    local tmp_file
    local inserted=0
    local line
    local existing

    if grep -q "<module>${service_name}</module>" "$pom_file"; then
        log_warn "Module ${service_name} already present in services/pom.xml"
        return 0
    fi

    tmp_file=$(mktemp)
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$inserted" -eq 0 && "$line" =~ ^[[:space:]]*\<module\>(.*)\</module\> ]]; then
            existing="${BASH_REMATCH[1]}"
            if [[ "$service_name" < "$existing" ]]; then
                printf '%s\n' "$module_line" >> "$tmp_file"
                inserted=1
            fi
        elif [[ "$inserted" -eq 0 && "$line" =~ ^[[:space:]]*\</modules\> ]]; then
            printf '%s\n' "$module_line" >> "$tmp_file"
            inserted=1
        fi
        printf '%s\n' "$line" >> "$tmp_file"
    done < "$pom_file"

    mv "$tmp_file" "$pom_file"
}

append_ports_env() {
    local ports_env="$1"
    local port_var="$2"
    local port="$3"
    local tmp_file
    local line
    local inserted=0

    if grep -q "^${port_var}=" "$ports_env"; then
        log_warn "${port_var} already present in quarkus-ports.env"
        return 0
    fi

    tmp_file=$(mktemp)
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Insert new service port before "# backend applications" (or at end of services block)
        if [[ "$inserted" -eq 0 && "$line" =~ ^#[[:space:]]*backend[[:space:]]+applications ]]; then
            printf '%s=%s\n' "$port_var" "$port" >> "$tmp_file"
            inserted=1
        fi
        printf '%s\n' "$line" >> "$tmp_file"
    done < "$ports_env"

    if [[ "$inserted" -eq 0 ]]; then
        printf '%s=%s\n' "$port_var" "$port" >> "$tmp_file"
    fi

    mv "$tmp_file" "$ports_env"
}

add_backbone_services_entry() {
    local json_file="$1"
    local service_name="$2"
    local alb_path="$3"
    local tmp_file

    # Absent on developer / client forks (no infra/); present when scaffolding in-core.
    [[ -f "$json_file" ]] || return 0

    if jq -e --arg name "$service_name" '.services[] | select(.serviceName == $name)' "$json_file" > /dev/null; then
        log_warn "Service ${service_name} already present in backbone-services.json"
        return 0
    fi

    tmp_file=$(mktemp)
    # Keep compact alb object style used by existing service entries
    jq --arg modulePath "services/${service_name}" \
        --arg serviceName "$service_name" \
        --arg albPath "$alb_path" \
        '.services += [{
            modulePath: $modulePath,
            serviceName: $serviceName,
            cognitoServiceAccount: true,
            deployment: "ecs",
            alb: { internalPathPattern: $albPath }
        }]' "$json_file" > "$tmp_file"
    mv "$tmp_file" "$json_file"
}

add_taskfile_wrapper() {
    local taskfile="$1"
    local task_alias="$2"
    local service_name="$3"
    local tmp_file
    local line
    local -a lines=()
    local i
    local bff_index=-1

    if grep -q "^  dev:${task_alias}:" "$taskfile"; then
        log_warn "Task dev:${task_alias} already present in taskfile.yml"
        return 0
    fi

    if ! grep -q "^  dev:bff:" "$taskfile"; then
        cat << EOF >> "$taskfile"

  dev:${task_alias}:
    desc: Quarkus dev - ${service_name}
    cmds:
      - task: dev:service
        vars:
          SERVICE: ${service_name}
EOF
        return 0
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        lines+=("$line")
    done < "$taskfile"

    for i in "${!lines[@]}"; do
        if [[ "${lines[$i]}" == "  dev:bff:" ]]; then
            bff_index=$i
            break
        fi
    done

    # Drop trailing blank lines immediately before dev:bff so spacing is consistent
    while ((bff_index > 0)) && [[ -z "${lines[$((bff_index - 1))]}" ]]; do
        unset "lines[$((bff_index - 1))]"
        lines=("${lines[@]}")
        ((bff_index--)) || true
    done

    tmp_file=$(mktemp)
    for i in "${!lines[@]}"; do
        if ((i == bff_index)); then
            cat << EOF >> "$tmp_file"

  dev:${task_alias}:
    desc: Quarkus dev - ${service_name}
    cmds:
      - task: dev:service
        vars:
          SERVICE: ${service_name}

EOF
        fi
        printf '%s\n' "${lines[$i]}" >> "$tmp_file"
    done
    mv "$tmp_file" "$taskfile"
}

print_followups() {
    local service_name="$1"
    local task_alias="$2"
    local alb_path="$3"
    local with_rds="$4"

    cat << EOF

Scaffold complete for ${service_name}.

Next steps (manual):
  1. Optionally add "task dev:${task_alias}" to .mertrc
  2. Add BFF routes / domain-clients when clients need this service
  3. Deploy via existing CDK / release workflows after merge
  4. Run locally: task dev:${task_alias}
EOF

    if [[ "$with_rds" -eq 1 ]]; then
        cat << EOF
  5. Ensure local Postgres is running for integration tests (Flyway schema: ${PACKAGE_SEGMENT})
EOF
    fi

    printf '\n'
}

# ---- Main -------------------------------------------------------------------

main() {
    local project_root dest_dir template_dir port
    local services_pom ports_env backbone_json root_taskfile
    local with_rds=0
    local service_arg=""
    local arg

    validate_dependencies

    for arg in "$@"; do
        case "$arg" in
            -h | --help)
                usage
                exit 0
                ;;
            --with-rds)
                with_rds=1
                ;;
            -*)
                log_error "Unknown option: ${arg}"
                usage
                exit 1
                ;;
            *)
                if [[ -n "$service_arg" ]]; then
                    log_error "Unexpected argument: ${arg}"
                    usage
                    exit 1
                fi
                service_arg="$arg"
                ;;
        esac
    done

    if [[ -z "$service_arg" ]]; then
        usage
        exit 1
    fi

    derive_service_names "$service_arg"

    project_root="$(get_project_root)"
    template_dir="${project_root}/services/template-service"
    dest_dir="${project_root}/services/${SERVICE_NAME}"
    services_pom="${project_root}/services/pom.xml"
    ports_env="${project_root}/config/quarkus-ports.env"
    backbone_json="${project_root}/infra/src/lib/constant/backbone-services.json"
    root_taskfile="${project_root}/taskfile.yml"

    if [[ ! -d "$template_dir" ]]; then
        log_error "Template not found at ${template_dir}"
        exit 1
    fi

    if [[ -e "$dest_dir" ]]; then
        log_error "Destination already exists: ${dest_dir}"
        exit 1
    fi

    if [[ "$SERVICE_NAME" == "template-service" ]]; then
        log_error "Cannot scaffold template-service onto itself"
        exit 1
    fi

    if [[ "$with_rds" -eq 1 ]]; then
        log_info "Scaffolding ${SERVICE_NAME} with RDS (package=${PACKAGE_SEGMENT}, class=${CLASS_PREFIX}, port=${PORT_VAR})"
    else
        log_info "Scaffolding ${SERVICE_NAME} without RDS (package=${PACKAGE_SEGMENT}, class=${CLASS_PREFIX}, port=${PORT_VAR})"
    fi

    copy_template_tree "$template_dir" "$dest_dir"
    if [[ "$with_rds" -eq 0 ]]; then
        strip_rds_for_stateless "$dest_dir"
    fi
    rename_java_paths "$dest_dir" "$PACKAGE_SEGMENT" "$CLASS_PREFIX"
    replace_tokens_in_tree "$dest_dir" "$SERVICE_NAME" "$PACKAGE_SEGMENT" "$CLASS_PREFIX" "$PORT_VAR"

    port="$(find_next_service_port "$ports_env")"
    insert_services_pom_module "$services_pom" "$SERVICE_NAME"
    append_ports_env "$ports_env" "$PORT_VAR" "$port"
    add_backbone_services_entry "$backbone_json" "$SERVICE_NAME" "$ALB_INTERNAL_PATH"
    add_taskfile_wrapper "$root_taskfile" "$TASK_ALIAS" "$SERVICE_NAME"

    log_info "Verifying module (compile + integration tests)..."
    (
        cd "$project_root"
        # Install reactor deps without re-running their tests; verify only the new module.
        ./mvnw -pl "services/${SERVICE_NAME}" -am install -DskipTests -q
        ./mvnw -pl "services/${SERVICE_NAME}" verify -q
    )

    print_followups "$SERVICE_NAME" "$TASK_ALIAS" "$ALB_INTERNAL_PATH" "$with_rds"
}

main "$@"
