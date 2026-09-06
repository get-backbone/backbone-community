## Forge-era 1.0.0 (2026-07-25)

### BREAKING CHANGE

- **rebrand**: rename platform Forge → Backbone. Maven coordinates `io.forge.core:forge-platform` → `io.backbone.core:backbone-platform`; Java packages `io.forge.{core,services,application}` → `io.backbone.*`; app config keys `forge.*` → `backbone.*` and env vars `FORGE_*` → `BACKBONE_*`; CDK stacks/resources `forge-*` → `backbone-*`; GitHub Packages registry `get-forge/forge-platform` → `get-backbone/backbone-platform`. The external `forge-kit` dependency (`io.forge.kit.*`, `io.forge:forge-*`, `io.forge.version`, `forge.observability.*`) is unchanged.
- **version**: reset project version `2.4.0` → `1.0.0` for the rebrand. Changelog history below is retained.

## Forge-era 2.4.0 (2026-07-07)

### Feat

- **infra**: improve CloudWatch dashboard labels and panel order
- **infra**: add runtime and datastore CloudWatch monitoring

### Fix

- **xray**: logging added for tracing purposes
- **infra**: re-run AMG provisioner after SigV4 datasource fix
- **infra**: correct AMG Prometheus SigV4 and revert Phase 9 env overrides

### Refactor

- **bloat**: Cursor adding bloat when simplest action is to teardown and rebuild

## Forge-era 2.3.2 (2026-07-03)

### Fix

- **no-op**: last fix was pom-only which does not (by design) trigger ECS image rebuild

## Forge-era 2.3.1 (2026-07-03)

### Fix

- **prometheus**: picking up forge-kit mod to differentiate between service collisions on CloudWatch Prometheus metrics push
- **infra**: append remote_write only to AMP PrometheusEndpoint
- **infra**: correct AMP remote-write URL and hibernate observability

## Forge-era 2.3.0 (2026-07-03)

### Feat

- **infra**: add observability VPC endpoints for NAT-less subnets

### Fix

- **config**: use formatted JSON exception output on deployed profiles
- **config**: register Redis cache DTOs for native image reflection
- **governance**: route ALB access logs to SSE-S3 bucket
- **monitoring**: use per-stack CloudWatch dashboard names
- **governance**: grant CloudTrail KMS access and extract IAM utils
- **ci**: install Node via nvm in infra workflows
- **ci**: use setup-node when nvm lacks .nvmrc version

## Forge-era 2.2.0 (2026-07-02)

### Feat

- **governance**: add governance evidence stack and ADR-0027
- **monitoring**: add per-stack CloudWatch monitoring and SNS alerts
- **observability**: wire forge-kit export and ECS runtime integration
- **observability**: add AMP, AMG, and Grafana dashboard provisioning

### Fix

- **test**: load metrics config in auth-service integration tests
- **governance**: add evidence access logging and L2 ALB log delivery
- **observability**: harden local dev config and bump forge-kit
- **ci**: trim unused OWASP suppression rules for forge-core
- **ci**: align OWASP with forge-kit aggregate scan pattern
- **deps**: adopt forge-kit 1.2.1 forge-logging
- **ci**: install ShellCheck 0.11 in hygiene workflow runners

### Refactor

- **utils**: consolidate infra utils by AWS resource and Forge stage
- **bash**: add validate_dependencies to test seed scripts
- **bash**: align grafana config and helpers with module template
- **bash**: align metrics scripts with template conventions
- **bash**: add Main section separator before main() entrypoints
- **bash**: wrap Quarkus container entrypoint in main()
- **bash**: standardize perf scripts layout to template conventions
- **bash**: standardize scripts/licence layout to template conventions
- **bash**: standardize .github/scripts layout to template conventions
- **bash**: standardize port-manager and scripts/test layout
- **bash**: align common.sh with module template layout
- **bash**: standardize scripts/docker layout to template conventions
- **bash**: standardize scripts/aws layout to template conventions
- **bash**: standardize script templates and bootstrap layout
- **bash**: polish portability follow-ups across scripts
- **bash**: fixing remaining concerns and removing continue-on-error: true from CI hygience check gate
- **bash**: cleanup of required cli tools approach
- **scripts**: consolidate update_envrc_key in common.sh
- **nvm**: removing proliferation of fixed nvm use directive; only required for infra module

## Forge-era 2.1.0 (2026-06-20)

### Feat

- **throttle**: add Redis-backed distributed rate limiting
- **cache**: add Redis-backed distributed caching for domain services
- **redis**: ElastiCache Redis cluster infrastructure
- **CloudFront**: migrate ui web module to CloudFront distribution + S3 (instead of ECS)

### Fix

- **cache**: keep qute-cache on Caffeine when Redis is the default backend
- **deps**: update quarkus platform updates to v3.36.1 (#82)

### Refactor

- **cache**: stripping registration endpoint cache support which was prep never implemented - reg insert is cache-aside
- **infra**: migrating hibernate to aws cli to avoid cdk/npx build/synth as latter is subject to drift
- **infra**: ditto missing secret
- **infra**: missing secrets for infra hibernate workflow
- **infra**: dropping IPv6 prefix-list ingress rules as unneccessary
- **infra**: fix to Jest ESM dependency chain which failed tests
- **infra**: mirror Cognito client secrets and tier log retention
- **infra**: CognitoIdp stack drift in relation to Lambda log groups - defining explicitly to counter
- **infra**: removing type-check of every test file in cdk tests
- **infra**: removed dormant port 80 listener on public ALB; historical throwback that was redirecting to 443, no longer needed since CloudFront edge routing refactor
- **infra**: Excluding cdk.context.json from forge-platform mirror fork
- **infra**: Restrict ingest ALB SG to CloudFront prefix lists
- **infra**: Remove orphaned regional WAF
- **cdk**: migrate the ECS toggle to full tear-down of cost-heavy stacks to optmise AWS spend in non-prod envs
- **comments**: explanatory lifecycle tier comments
- **cdk**: split stack termination protection from state concerns
- **cdk**: GH role needs CloudFront permissions to invalidate the distribution on redeployment of the static frontend
- **cdk**: static site S3 bucket policies
- **cdk**: CloudFront standard logging still writes to S3 using ACLs; need to change bucket object ownership
- **cdk**: cross-region refs required for DomainStack
- **cdk**: dependencies do need to be declarative as they were before, introduced a bug by removing
- **cdk**: us-east-1 needs to be bootstrapped
- **cdk**: splitting global CloudFront stack provisioning

## Forge-era 2.0.21 (2026-05-05)

### Perf

- **tuning**: testing with 2 count of ECS instances and think we are seeing datasource connection pool exhaustion

## Forge-era 2.0.20 (2026-05-05)

### Refactor

- **test**: inconsistent test target fix
- **test**: seed test data cleanup; clarified the control surface and refactored based on different test data lifecycles
- **taskfile**: naming conventions drifted a bit; realigning

### Perf

- **tuning**: connection pool tuning for http and db at 200 VUs

## Forge-era 2.0.19 (2026-05-03)

### Fix

- **ttl**: quarkus rest client connection pool ttl is in ms
- **workflow**: changes to config dir now trigger the deployment pipeline

### Refactor

- **perf**: reducing collision risk on user email generation for performance tests to negligible
- **perf**: reducing noisy EC2 instance provisioning script output

### Perf

- **ttl**: recycling pooled connections before a internal ALB idle timeout (60s)

## Forge-era 2.0.18 (2026-05-03)

### Fix

- **ecs**: trigger to redeploy all ECS services (not sure previous config throttle.properties suffices)
- **perf**: INT env is throttling on performance tests; refactoring to toggle rate-limiting by profile (effective env stage name)

## Forge-era 2.0.17 (2026-05-03)

### Fix

- **documents**: document-service bug in bucket name configuration

## Forge-era 2.0.16 (2026-05-03)

### Fix

- **native**: need to make a non-pom file change in document-service to trigger runtime ECS deploy

## Forge-era 2.0.15 (2026-05-03)

### Fix

- **native**: apache tika document parsing issue in document-service with native image

## Forge-era 2.0.14 (2026-05-03)

### Fix

- **native**: native image reflection issue with CacheKeyGenerator implementations
- **infra**: RDS requires 2 subnets which conflicted with the change to 1 AZ to reduce costs

### Refactor

- **perf**: just breaking up the perf load generator script to aws-specific resource helpers for maintenance
- **perf**: supporting test users / cleanup in AWS proper
- **perf**: cleaning up on seed test data configuration
- **infra**: cost optimisation; reducing AZ count to mirror ECS task count

## Forge-era 2.0.13 (2026-05-01)

### Fix

- **native**: Native image strips Lombok-generated constructors/setters from Jackson's view unless the class is registered

## Forge-era 2.0.12 (2026-05-01)

### Fix

- **native**: native images builds did not include the public licence file key

## Forge-era 2.0.11 (2026-05-01)

### Fix

- **native**: libs dir trigger version bump and image builds
- **native**: Fixing invalid maximum heap size

## Forge-era 2.0.10 (2026-05-01)

### Fix

- **native**: optimisation to build only changes

## Forge-era 2.0.9 (2026-05-01)

### Fix

- **native**: remove root dir as a global var as causing issues accross workflows
- **native**: self-hosted gh runner needs mvnw to output mvn version to stdout maybe

## Forge-era 2.0.8 (2026-05-01)

### Fix

- **native**: all services now succeeding the maven profile build

## Forge-era 2.0.7 (2026-05-01)

### Fix

- **native**: odd dependency required for GraalVM touches jakarta.mail.Part (related to jaxb in document-service)

## Forge-era 2.0.6 (2026-05-01)

### Fix

- **native**: trigger for native module rebuild

## Forge-era 2.0.5 (2026-05-01)

### Fix

- **native**: single threading mvnd during native builds as it's trashing my self-hosted gha runner

## Forge-era 2.0.4 (2026-05-01)

### Fix

- **native**: minimal change to trigger deployable unit of work in ECS

## Forge-era 2.0.3 (2026-05-01)

### Fix

- **native**: removing workflow dispatch trigger

## Forge-era 2.0.2 (2026-05-01)

### Refactor

- **rename**: slight tweak to task name to indicate not exposed
- **rename**: backend-actor renamed more accurately to actor-bff (audience-function)

## Forge-era 2.0.1 (2026-04-28)

### Fix

- **deps**: update aws-sdk-js-v3 monorepo to v3.1038.0 (#75)
- **deps**: update quarkus platform updates to v3.34.6 (#77)
- **deps**: update dependency org.projectlombok:lombok to v1.18.46 (#81)
- **deps**: update dependency org.projectlombok:lombok to v1.18.46 (#76)
- **deps**: update dependency io.quarkiverse.amazonservices:quarkus-amazon-services-bom to v3.17.0 (#78)
- **deps**: update dependency aws-cdk-lib to v2.251.0 (#80)

## Forge-era 2.0.0 (2026-04-27)

### BREAKING CHANGE

- Requires CI/CD repository secret name change

### Refactor

- **OAuth2**: Made LinkedIn authentication an optional configuration for clients

## Forge-era 1.8.2 (2026-04-25)

### Fix

- **infra**: fixing node upgrade issues with missing dependency on infra tests

## Forge-era 1.8.1 (2026-04-25)

### Fix

- **metrics**: disabling outbound http client binder as noisy and unused (no dashboards currently on outbound, only inbound)
- **notifications**: auto-verify sender email address on quarkus:dev mode startup
- **deps**: update dependency io.quarkiverse.amazonservices:quarkus-amazon-services-bom to v3.16.0 (#64)
- **deps**: update dependency constructs to v10.6.0 (#63)
- **deps**: update quarkus platform updates to v3.34.5 (#74)
- **deps**: update aws-sdk-js-v3 monorepo to v3.1032.0 (#61)
- **deps**: update dependency aws-cdk-lib to v2.250.0 (#62)
- **deps**: update dependency yaml to v2.8.3 (#65)
- **deps**: update quarkus platform updates to v3.34.3 (#66)
- **deps**: update tika monorepo to v3.3.0 (#67)
- **deps**: update dependency org.projectlombok:lombok to v1.18.44
- **deps**: update dependency software.amazon.awssdk:bom to v2.42.34
- **deps**: update dependency com.bucket4j:bucket4j_jdk17-core to v8.18.0

### Refactor

- **cleanup**: error handling cleanup on failed auth; just reducing noisy logs
- **auth**: password validation in dto tier to reflect cognito
- **github**: repository org transfer
- **tools**: moving toolchain install from README to taskfile

## Forge-era 1.8.0 (2026-04-14)

### Feat

- **security**: Encrypting postgres db at rest (AWS-managed key)

### Refactor

- **cleanup**: todo's removed, esp those where we had messy frontend app leakage

## Forge-era 1.7.2 (2026-04-11)

### Fix

- **taskfile**: recent refactor lost a couple of localstack tasks; replaced and fit nicely in our new task architecture
- **lefthook**: added markdown/yaml linters and trufflehog security tool to lefthook pre-push

### Refactor

- **rename**: scripts/init --> scripts/bootstrap only

## Forge-era 1.7.1 (2026-04-10)

### Fix

- **scheme**: missed some http/s references now we have flipped to certificate on the public ALB

### Refactor

- **config**: moved aws region out of properties file to dedicated client platform config
- **typo**: fixed

## Forge-era 1.7.0 (2026-04-10)

### Feat

- **infra**: reimplementing https/certificate on the public ALB now deployment to AWS is confirmed

### Refactor

- **region**: AWS region and account id are now GitHub Repository variables leaving aws.properties as only other single source of truth
- **chore**: minor cleanup only

## Forge-era 1.6.7 (2026-04-06)

### Fix

- **infra**: ALB listener paths needed to be more exact so as not to mistakenly capture non-API requests

### Refactor

- **naming**: consolidating the internal ALB paths as now all the same (suffix removed) and renaming for consistency/clarity

## Forge-era 1.6.6 (2026-04-06)

### Fix

- **routing**: REST client endpoint URLs duplicating the /auth etc. suffix
- **infra**: playing with health check thresholds to see if I can get consistent ALB response

## Forge-era 1.6.5 (2026-04-06)

### Fix

- **noop**: false positive to trigger ECS deployment (must be non pom file change)

## Forge-era 1.6.4 (2026-04-06)

### Fix

- **infra**: ALB healthcheck timeout was too aggressive and not allowing service deployments

## Forge-era 1.6.3 (2026-04-06)

### Fix

- **gha**: workflow 06 now does ecs update-service after being triggered by new images in the ECR repo

## Forge-era 1.6.2 (2026-04-06)

### Fix

- **ci**: bug in module resolution script for 06-ecs-runtime-deploy

## Forge-era 1.6.1 (2026-04-06)

### Fix

- **ci**: chaining ECS image deployment to package publishing and uploads to ECR

## Forge-era 1.6.0 (2026-04-06)

### Feat

- **infra**: extract root apex domain name to client-generated config file

### Refactor

- **client**: removing need for window.location.origin in client web as felt flaky

## Forge-era 1.5.0 (2026-04-05)

### Feat

- **infra**: adding A record so frontend is exposed from sub domain int.* etc
- **infra**: moving licence file to CDK and GitHub secrets from manual script upload

### Fix

- **infra**: ECR repo was expiring images incorrectly
- **infra**: grant read for ECS task role on Cognito user pool app client secrets (both actor and service pools)
- **infra**: VPC endpoint required for SSM when no NAT Gateway present; also ECS task role requires read grant
- **infra**: IAM resource regex on service account secrets uses : prefix
- **infra**: ECS tasks need access to service account secrets
- **infra**: ECS task execution role permissions for secrets/ssm access during provisioning

## Forge-era 1.4.5 (2026-04-05)

### Fix

- **infra**: user pool lookup by id rather than arn

## Forge-era 1.4.4 (2026-04-05)

### Refactor

- **postgres**: cleaned up postgres db name and configuration

## Forge-era 1.4.3 (2026-04-05)

### Fix

- **auth**: finally found our auth bug; reference impl extractor in forge-kit to blame
- **gha**: cleaning up the gha workflows

## Forge-era 1.4.2 (2026-04-04)

### Fix

- **gha**: hoping to chain triggers together post- 04-publish-packages

## Forge-era 1.4.1 (2026-04-04)

### Fix

- **lefthook**: build cache issue with protobuf now we are verify-fast restricted to just test
- **auth**: bug fix in CognitoUserPrincipalExtractor, which now prefers email then cognito:username, matching the same USERNAME used for login / SECRET_HASH

### Refactor

- **infra**: migrating GHA role and permissions to CDK
- **gha**: splitting lightweight/heavyweight toolchains so we can be more explicit/optimised in imports to gha workflows
- **infra**: rename/reorg of the infra triggers as infra bootstrap needs to run before build-test so Cognito resources are in place
- **infra**: 01-build-test aws tests now succeed with infra bootstrap / seed resources

## Forge-era 1.4.0 (2026-04-03)

### Feat

- **infra**: SES configuration
- **infra**: make ECS task count and NAT Gateway count configurable for clients
- **infra**: adding storage stack; rds, dynnamo, s3 and cognito resources

### Refactor

- **infra**: aligning LinkedIn secrets/env vars naming convention
- **infra**: retention policy configuration based on stage.
- **infra**: renaming only of infra commands/tasks to separate local cdk from aws deployments
- **cognito**: moved all cognito setup to development CDK stack instead of bash scripts
- **deploy**: all modules and services now deploy to AWS ECS successfully

## Forge-era 1.3.0 (2026-03-17)

### Feat

- **infra**: datastore stack

## Forge-era 1.2.2 (2026-03-17)

### Refactor

- **mvn**: making the github deploy token a reusable script for workflow conciseness

## Forge-era 1.2.1 (2026-03-16)

### Refactor

- **cleanup**: docs and tidy up really, nothing of note
- **infra**: docs and refactoring of cdklocal taskfile

## Forge-era 1.2.0 (2026-03-09)

### Feat

- **infra**: moving public hosted zone (route 53) out to it's own stack
- **infra**: network, security and runtime stacks deploying to AWS real
- **infra**: first pass at infra impl with network, security and runtime stacks

### Fix

- **deps**: update dependency com.google.protobuf:protobuf-java to v4
- **deps**: update dependency software.amazon.awssdk:bom to v2.42.8
- **deps**: update dependency com.google.protobuf:protobuf-java to v3.25.8

## Forge-era 1.1.2 (2026-02-21)

### Fix

- **deps**: update quarkus platform updates to v3.31.4
- **deps**: update dependency software.amazon.awssdk:bom to v2.41.32

## Forge-era 1.1.1 (2026-02-17)

### Fix

- **mirror**: script is working locally with PAT but not in CI/CD; trying a different url

## Forge-era 1.1.0 (2026-02-16)

### Feat

- **mirror**: mirror this repo to forge-platform

### Fix

- **mirror**: reactor libs pom rewritten to reference published github packages

## Forge-era 1.0.1 (2026-02-16)

### Fix

- **bump**: gpg signing issue fix to allow version bump with pinned commitizen version
- **bump**: attempting to suppress git commit from trying to open an editor - should use default message instead
- **tests**: reverting to prior unit/int test execution with flags which gave greater control/isolation
- **package**: the reactor task was running the lifecycle for every module the reactor depends on, so all those libs were being deployed as well as the reactor

## Forge-era 1.0.0 (2026-02-15)

### BREAKING CHANGE

- placeholder to bump version

### Feat

- **publish**: major bump to trigger reactor uber jar publish

## v1.1.0 (2026-08-11)

### Feat

- **ci**: add HEAD-only manual ECR rebuild escape hatch

### Fix

- **bff**: use OpenApiFilter stages instead of deprecated value

## v1.0.1 (2026-08-11)

### Fix

- **ci**: make runtime-modules-changed.sh executable

## v1.0.0 (2026-08-11)

### BREAKING CHANGE

- Replace io.forge forge-kit dependencies with
io.backbone:backbone-*, imports io.backbone.kit.*, config keys
backbone.observability.*, and registry get-backbone/backbone-kit.
Point io.backbone.version at 0.0.0 until the kit pipeline publishes v1.0.0.
- infrastructure resource names, stack ids and env vars renamed.
- Maven coordinates, Java packages, config keys and env vars renamed.
- Requires CI/CD repository secret name change
- hoping to trigger a version bump and from there a publish event
- the issue was service auth looking at access token not the custom service pool service_id
- service-to-service auth implemented via Cognito service accounts
- removal of sessions

### Feat

- **ci**: auto-promote ECS deploy across INT/STAGE/PROD
- **bff**: expose document list and subscription status
- **infra**: add optional internal ALB HTTPS via platform-config
- **security**: add CloudFront HSTS and TLS-only edge headers
- **security**: add CloudFront Content-Security-Policy headers
- **security**: enforce non-root containers and block privileged ECS
- **docker**: finish Floci local Cognito and docs cleanup
- **docker**: provision Floci resources and Floci-only IT seeds
- **aws**: point Cognito clients and JWT issuer at Floci locally
- **metrics**: add X-Ray Trace Statistics to Platform Ops
- **metrics**: add AMG CloudWatch platform ops starter dashboard
- **audit**: add delivery metrics and fix Redis cache value types
- **metrics**: expand Grafana coverage and align Redis caching
- **template**: golden template service automation
- **infra**: add us-east-1 static edge global monitoring stack
- **infra**: add stack monitoring alarms and reorganize monitoring layout
- **aws**: add X-Ray OTLP account bootstrap
- **infra**: improve CloudWatch dashboard labels and panel order
- **infra**: add runtime and datastore CloudWatch monitoring
- **infra**: add observability VPC endpoints for NAT-less subnets
- **governance**: add governance evidence stack and ADR-0027
- **monitoring**: add per-stack CloudWatch monitoring and SNS alerts
- **observability**: wire forge-kit export and ECS runtime integration
- **observability**: add AMP, AMG, and Grafana dashboard provisioning
- **throttle**: add Redis-backed distributed rate limiting
- **cache**: add Redis-backed distributed caching for domain services
- **redis**: ElastiCache Redis cluster infrastructure
- **CloudFront**: migrate ui web module to CloudFront distribution + S3 (instead of ECS)
- **security**: Encrypting postgres db at rest (AWS-managed key)
- **infra**: reimplementing https/certificate on the public ALB now deployment to AWS is confirmed
- **infra**: extract root apex domain name to client-generated config file
- **infra**: adding A record so frontend is exposed from sub domain int.* etc
- **infra**: moving licence file to CDK and GitHub secrets from manual script upload
- **infra**: SES configuration
- **infra**: make ECS task count and NAT Gateway count configurable for clients
- **infra**: adding storage stack; rds, dynnamo, s3 and cognito resources
- **infra**: datastore stack
- **infra**: moving public hosted zone (route 53) out to it's own stack
- **infra**: network, security and runtime stacks deploying to AWS real
- **infra**: first pass at infra impl with network, security and runtime stacks
- **mirror**: mirror this repo to forge-platform
- **cleanup**: minor code cleanups
- **publish**: major bump in hope of triggering reactor uber jar publish
- **licence**: licence file generation and startup validation
- **audit**: Phase I of the audit-service
- **metrics**: queued / sent / failed metrics for the notification-service
- **notifications**: unsubscribe from emails
- **notifications**: notification-service impl with email (SES) as phase I
- **forge-kit**: baselined forge-kit at 1.0.0 as I think we are done with open-sourcing
- **migration**: minor utility extraction to forge-kit
- **kit**: migrated throttling out to public repo; also renamed the metrics package to avoid namespace clash
- **validation**: beans validation at resource/dto layer
- **logging**: minor improvement to startup display
- **linkedin**: linkedin account login now working if account linked during registration
- **cache**: flipped the manual token cache out to use service-tokens quarkus cache we use elsewhere
- **linkedin**: linkedin account linking on registration
- **logging**: service boundary logging impl
- **cache**: document service cache impl
- **cache**: candidate profile cache (using cache-aside pattern for 2-phase resume retrieval)
- **metrics**: cache metrics dashboard added
- **cache**: first caffeine cache implementation on JWT tokens
- **perf-testing**: performance testing framework with k6
- **metrics**: circuit breaker metrics impl and dashboard
- **metrics**: database operational metrics - duration, max, avg etc. on both dynamodb and postgres databases
- **metrics**: database connection pool metrics
- **metrics**: match service operation metrics
- **metrics**: candidate operations metrics
- **metrics**: document operations metrics
- **metrics**: rate-limited throttling now added to metrics
- **throttling**: implementing throttling in all services
- **throttling**: base throttling impl to rate limit auth/unauth requests (sits in front of all other filters)
- **health**: health checks framework and various implementations
- **metrics**: baseline metrics impl with http, jvm and user dashboards
- **auth**: service account auth
- **profile**: profile page now displays registration and resume data
- **registration**: major module refactor to support candidate registration
- **auth**: registration fully implemented
- **oidc**: LinkedIn authentication via Oauth2
- **auth**: web demo authentication is now a cross-cutting concern, not programmatic
- **demo**: feature toggle for investor demo and augmenting matches
- **demo**: web frontend for user registration
- **demo**: cleanup and improvement of the web-demo frontend
- **REST**: implementing REST client to call auth-service; login now working against Cognito user pool in sandbox AWS
- **REST**: implementing REST client to actually call parse-service from backend controller tier
- **web**: adding a few frontend demo pages
- **web**: demo frontend talking to backend
- **auth**: secure resource endpoints and check for valid JWT access token; dev (only) resource endpoint provided to test/demonstrate working implementation
- **quarkus**: adding out of the box features - metrics, health, swagger endpoints plus fault tolerance
- **tracing**: adding tracing spans to resource endpoints and services
- **match**: first pass at matching candidate to jobs; this isn't robust until we receive full (paid) access to the textkernel API and typical request/response and workflows
- **logging/tracing**: logging and opentelemetry tracing setup for local/AWS (minor config switch only)
- **bump**: empty commit for release bump; SemVer major as think this is now working
- **cz-bump**: missing tag again; recreated manually and hope cz now finds a diff with this feat: commit
- **cz-bump**: another blast
- **cz-bump**: still we go
- **cz-bump**: dummy commit to ensure bump is actually working when we have a feat: commit
- **bump**: dummy commit to ensure bump is actually working when we have a feat: commit
- **textkernel**: save documents (resume/job specs) to S3 before parsing
- **textkernel**: missed some stuff
- **taskkernel**: taskkernel service impl incl dummy response
- **auth-service**: auth-service implementation with Quarkus integration (component) test
- **cognito**: Authentication and registration against AWS Cognito sandbox environment
- **auth**: cognito endpoint now needs to be accessible for IT test success
- **auth**: Cognito/OICD user auth and service-to-service JWT auth basic implementations
- **ssl**: Keycloak server behind SSL
- **auth**: Adding thymeleaf and dynamic index page
- **rbac**: Demonstrating RBAC once user authenticated with realm role from keycloak
- **auth**: Logout now works as expected
- **auth**: Frontend web app authentication with Keycloak
- **api**: Allow authenticated service1 to call authenticated service2
- **service2**: Ensuring service2 can be reached with authenticated Bearer JWT
- SemVer impl in releasable war file names
- Release Please workflow
- **gha**: Upload artifacts to GHA; means it's available via the REST API.
- **gha**: Scheduled cleanup of GHA workflow runs.
- **swagger**: Swagger UI and API docs impl.
- **oidc**: Securing service1 resource server with OIDC Bearer JWT served from keycloak (non-production config).
- **frontend**: GHA config for frontend.
- **frontend**: Split frontend out as different security profile / configuration required. Security is commented out in backend services currently.
- **xss**: XSS implementation.
- **gha**: Found GHA Marketplace Actions for SOPS execution.
- **encryption**: Mozilla sops/age implementation with SSL certs.
- **resilience**: Basic circuit-breaker impl.
- **mvn**: Multi-core mvn build and parallel JUnit 5 test execution; also using maven daemon mvnd wrapper.
- **logs**: Improved purpose of logging configuration and separation of responsibilities.
- **service**: Use RestTemplateBuilder to confirm service-to-service communication. Confirm zipkin trace ids.
- **adr**: Adding support for Architecture Decision Records.

### Fix

- **alb**: removed suppressed security nag and fixed ALB listener so it doesn't open 0.0.0.0 on instantiation
- **bff**: exclude kit circuit-breaker probe from OpenAPI
- **bootstrap**: write AWS_REGION into .envrc.local
- **ci**: skip quarkus:build during Clover integration coverage
- **ci**: bind Temurin jmods cleanup trap before local goes out of scope
- **deps**: pin Bouncy Castle jdk18on to 1.85 for OWASP CVEs
- **ci**: restore Temurin jmods for ProGuard; exclude reactor from Clover
- **security**: tighten Quarkus CORS allowlists
- **ci**: keep postgres out of shell-tools parallel group
- **notification**: truncate IT tables atomically in tearDown
- **ci**: split parallel setup to avoid apt lock contention
- **ci**: seed Floci Cognito IT fixtures before integration tests
- **ci**: align Floci region and pin emulator to 1.5.34
- **actor**: align Redis cache return type with ActorRecord
- **deps**: downgrade Quarkus platform to 3.36.1
- **deps**: bump forge-kit to 1.3.5
- **deps**: update quarkus platform updates to v3.38.0 (#86)
- **spotbugs**: exclude TemplateEventRepository EI_EXPOSE_REP2
- **infra**: trust classic and immutable GitHub OIDC subjects
- **ci**: configure Maven GitHub Packages credentials in test jobs
- **audit**: populate correlationId from logging MDC
- **infra**: grant AMG CloudWatch Logs access and enable plugin admin
- **infra**: use modern ALB access log delivery principal
- **ci**: stop release bumps committing shellcheck extract
- **infra**: keep SES reputation alarms on stable CFN logical IDs
- **infra**: correct monitoring alarm preset types for tsc build
- **xray**: logging added for tracing purposes
- **infra**: re-run AMG provisioner after SigV4 datasource fix
- **infra**: correct AMG Prometheus SigV4 and revert Phase 9 env overrides
- **no-op**: last fix was pom-only which does not (by design) trigger ECS image rebuild
- **prometheus**: picking up forge-kit mod to differentiate between service collisions on CloudWatch Prometheus metrics push
- **infra**: append remote_write only to AMP PrometheusEndpoint
- **infra**: correct AMP remote-write URL and hibernate observability
- **config**: use formatted JSON exception output on deployed profiles
- **config**: register Redis cache DTOs for native image reflection
- **governance**: route ALB access logs to SSE-S3 bucket
- **monitoring**: use per-stack CloudWatch dashboard names
- **governance**: grant CloudTrail KMS access and extract IAM utils
- **ci**: install Node via nvm in infra workflows
- **ci**: use setup-node when nvm lacks .nvmrc version
- **test**: load metrics config in auth-service integration tests
- **governance**: add evidence access logging and L2 ALB log delivery
- **observability**: harden local dev config and bump forge-kit
- **ci**: trim unused OWASP suppression rules for forge-core
- **ci**: align OWASP with forge-kit aggregate scan pattern
- **deps**: adopt forge-kit 1.2.1 forge-logging
- **ci**: install ShellCheck 0.11 in hygiene workflow runners
- **cache**: keep qute-cache on Caffeine when Redis is the default backend
- **deps**: update quarkus platform updates to v3.36.1 (#82)
- **ttl**: quarkus rest client connection pool ttl is in ms
- **workflow**: changes to config dir now trigger the deployment pipeline
- **ecs**: trigger to redeploy all ECS services (not sure previous config throttle.properties suffices)
- **perf**: INT env is throttling on performance tests; refactoring to toggle rate-limiting by profile (effective env stage name)
- **documents**: document-service bug in bucket name configuration
- **native**: need to make a non-pom file change in document-service to trigger runtime ECS deploy
- **native**: apache tika document parsing issue in document-service with native image
- **native**: native image reflection issue with CacheKeyGenerator implementations
- **infra**: RDS requires 2 subnets which conflicted with the change to 1 AZ to reduce costs
- **native**: Native image strips Lombok-generated constructors/setters from Jackson's view unless the class is registered
- **native**: native images builds did not include the public licence file key
- **native**: libs dir trigger version bump and image builds
- **native**: Fixing invalid maximum heap size
- **native**: optimisation to build only changes
- **native**: remove root dir as a global var as causing issues accross workflows
- **native**: self-hosted gh runner needs mvnw to output mvn version to stdout maybe
- **native**: all services now succeeding the maven profile build
- **native**: odd dependency required for GraalVM touches jakarta.mail.Part (related to jaxb in document-service)
- **native**: trigger for native module rebuild
- **native**: single threading mvnd during native builds as it's trashing my self-hosted gha runner
- **native**: minimal change to trigger deployable unit of work in ECS
- **native**: removing workflow dispatch trigger
- **deps**: update aws-sdk-js-v3 monorepo to v3.1038.0 (#75)
- **deps**: update quarkus platform updates to v3.34.6 (#77)
- **deps**: update dependency org.projectlombok:lombok to v1.18.46 (#81)
- **deps**: update dependency org.projectlombok:lombok to v1.18.46 (#76)
- **deps**: update dependency io.quarkiverse.amazonservices:quarkus-amazon-services-bom to v3.17.0 (#78)
- **deps**: update dependency aws-cdk-lib to v2.251.0 (#80)
- **infra**: fixing node upgrade issues with missing dependency on infra tests
- **metrics**: disabling outbound http client binder as noisy and unused (no dashboards currently on outbound, only inbound)
- **notifications**: auto-verify sender email address on quarkus:dev mode startup
- **deps**: update dependency io.quarkiverse.amazonservices:quarkus-amazon-services-bom to v3.16.0 (#64)
- **deps**: update dependency constructs to v10.6.0 (#63)
- **deps**: update quarkus platform updates to v3.34.5 (#74)
- **deps**: update aws-sdk-js-v3 monorepo to v3.1032.0 (#61)
- **deps**: update dependency aws-cdk-lib to v2.250.0 (#62)
- **deps**: update dependency yaml to v2.8.3 (#65)
- **deps**: update quarkus platform updates to v3.34.3 (#66)
- **deps**: update tika monorepo to v3.3.0 (#67)
- **deps**: update dependency org.projectlombok:lombok to v1.18.44
- **deps**: update dependency software.amazon.awssdk:bom to v2.42.34
- **deps**: update dependency com.bucket4j:bucket4j_jdk17-core to v8.18.0
- **taskfile**: recent refactor lost a couple of localstack tasks; replaced and fit nicely in our new task architecture
- **lefthook**: added markdown/yaml linters and trufflehog security tool to lefthook pre-push
- **scheme**: missed some http/s references now we have flipped to certificate on the public ALB
- **infra**: ALB listener paths needed to be more exact so as not to mistakenly capture non-API requests
- **routing**: REST client endpoint URLs duplicating the /auth etc. suffix
- **infra**: playing with health check thresholds to see if I can get consistent ALB response
- **noop**: false positive to trigger ECS deployment (must be non pom file change)
- **infra**: ALB healthcheck timeout was too aggressive and not allowing service deployments
- **gha**: workflow 06 now does ecs update-service after being triggered by new images in the ECR repo
- **ci**: bug in module resolution script for 06-ecs-runtime-deploy
- **ci**: chaining ECS image deployment to package publishing and uploads to ECR
- **infra**: ECR repo was expiring images incorrectly
- **infra**: grant read for ECS task role on Cognito user pool app client secrets (both actor and service pools)
- **infra**: VPC endpoint required for SSM when no NAT Gateway present; also ECS task role requires read grant
- **infra**: IAM resource regex on service account secrets uses : prefix
- **infra**: ECS tasks need access to service account secrets
- **infra**: ECS task execution role permissions for secrets/ssm access during provisioning
- **infra**: user pool lookup by id rather than arn
- **auth**: finally found our auth bug; reference impl extractor in forge-kit to blame
- **gha**: cleaning up the gha workflows
- **gha**: hoping to chain triggers together post- 04-publish-packages
- **lefthook**: build cache issue with protobuf now we are verify-fast restricted to just test
- **auth**: bug fix in CognitoUserPrincipalExtractor, which now prefers email then cognito:username, matching the same USERNAME used for login / SECRET_HASH
- **deps**: update dependency com.google.protobuf:protobuf-java to v4
- **deps**: update dependency software.amazon.awssdk:bom to v2.42.8
- **deps**: update dependency com.google.protobuf:protobuf-java to v3.25.8
- **deps**: update quarkus platform updates to v3.31.4
- **deps**: update dependency software.amazon.awssdk:bom to v2.41.32
- **mirror**: script is working locally with PAT but not in CI/CD; trying a different url
- **mirror**: reactor libs pom rewritten to reference published github packages
- **bump**: gpg signing issue fix to allow version bump with pinned commitizen version
- **bump**: attempting to suppress git commit from trying to open an editor - should use default message instead
- **tests**: reverting to prior unit/int test execution with flags which gave greater control/isolation
- **package**: the reactor task was running the lifecycle for every module the reactor depends on, so all those libs were being deployed as well as the reactor
- **bump**: deleting changelog content
- **bump**: Writing a tag message into the file git opens
- **bump**: Set GIT_EDITOR=true before running cz bump
- **bump**: Forcing lightweight tags so git won't prompt for a message
- **bump**: ignoring changelog
- **cz**: issue seems to be that i cleared the CHANGELOG
- **publish**: attempting to publish uber jar of reactor libs
- **publish**: attempting to publish uber jar of reactor libs
- **deps**: update dependency software.amazon.awssdk:bom to v2.41.20
- **deps**: update dependency com.bucket4j:bucket4j_jdk17-core to v8.16.1
- **deps**: update dependency io.quarkiverse.amazonservices:quarkus-amazon-services-bom to v3.14.1
- **notifications**: hopefully got to the bottom of our hanging IT test issue
- **audit**: bug fixes for bean discovery and running server with async context
- **forge-kit**: need bumped dependencies
- **notifications**: notification-service emails now working queued --> processed
- **ci**: forgot to add notifications-service to the CI build
- **deps**: update dependency software.amazon.awssdk:bom to v2.41.10
- **deps**: update dependency io.quarkiverse.amazonservices:quarkus-amazon-services-bom to v3.13.0
- **forge-kit**: bumping version to latest
- **web**: resurrecting the front-end
- **pom**: missed migration of metrics module to forge-kit
- **pom**: think i missed a deleted module dependency
- **401**: auth issue with GitHub packages; using the same mechanism as the public repo / local download
- **deps**: update quarkus platform updates to v3.30.6 (#113)
- **deps**: update dependency software.amazon.awssdk:bom to v2.41.4 (#112)
- **deps**: update dependency software.amazon.awssdk:bom to v2.41.2 (#111)
- **deps**: update dependency software.amazon.awssdk:bom to v2.41.1 (#110)
- **deps**: update dependency software.amazon.awssdk:bom to v2.41.0 (#109)
- **metrics**: missed service metrics on CandidateService#register
- **deps**: update dependency com.bucket4j:bucket4j_jdk17-core to v8.16.0 (#107)
- **deps**: update dependency software.amazon.awssdk:bom to v2.40.16 (#104)
- **deps**: update quarkus platform updates to v3.30.5 (#105)
- **deps**: update dependency software.amazon.awssdk:bom to v2.40.13 (#103)
- **deps**: update dependency software.amazon.awssdk:bom to v2.40.12 (#102)
- **deps**: update dependency software.amazon.awssdk:bom to v2.40.11 (#101)
- **deps**: update quarkus platform updates to v3.30.4 (#100)
- **deps**: update dependency software.amazon.awssdk:bom to v2.40.10 (#99)
- **auth**: finally fixing token issues
- **auth**: few fixes given the last few huge drops on service auth
- **deps**: update dependency org.apache.commons:commons-collections4 to v4.5.0 (#97)
- **deps**: update dependency software.amazon.awssdk:bom to v2.40.9 (#96)
- **deps**: update dependency software.amazon.awssdk:bom to v2.40.8 (#94)
- **dependency**: inadvertently introduced incorrect dependency, reverting
- **deps**: update quarkus platform updates to v3.30.3 (#93)
- **deps**: update dependency software.amazon.awssdk:bom to v2.40.6 (#92)
- **deps**: update dependency software.amazon.awssdk:bom to v2.40.5 (#91)
- **deps**: update dependency io.quarkiverse.web-bundler:quarkus-web-bundler to v2.0.2 (#90)
- **deps**: update dependency io.quarkiverse.web-bundler:quarkus-web-bundler to v2 (#89)
- **deps**: update dependency software.amazon.awssdk:bom to v2.40.3 (#87)
- **deps**: update quarkus platform updates to v3.30.2 (#86)
- **deps**: update dependency software.amazon.awssdk:bom to v2.40.1 (#85)
- **deps**: update dependency software.amazon.awssdk:bom to v2.39.6 (#83)
- **deps**: update quarkus platform updates to v3.30.1 (#81)
- **deps**: update dependency software.amazon.awssdk:bom to v2.39.5 (#80)
- **deps**: update dependency software.amazon.awssdk:bom to v2.39.3 (#79)
- **deps**: update dependency software.amazon.awssdk:bom to v2.39.2 (#75)
- **deps**: update dependency software.amazon.awssdk:bom to v2.39.1 (#74)
- **merge-conflict**: new pom file didn't get bumped on merge conflict when all the others got rebased
- **deps**: update dependency software.amazon.awssdk:bom to v2.39.0 (#72)
- **deps**: update quarkus platform updates to v3.29.4 (#71)
- **deps**: update dependency io.quarkiverse.amazonservices:quarkus-amazon-services-bom to v3.12.1 (#65)
- **deps**: update quarkus platform updates to v3.29.3 (#69)
- **deps**: update dependency software.amazon.awssdk:bom to v2.38.9 (#66)
- **test**: various minor test bug fixes and cleanup (not reusing transactionIds across tests etc) for clarity
- **localstack**: minor path bug in taskfile
- **pom**: think some pom versions got messed up in the last big rebase
- **deps**: update dependency software.amazon.awssdk:bom to v2.38.4 (#62)
- **deps**: update dependency com.fasterxml.jackson.datatype:jackson-datatype-jsr310 to v2.20.1 (#63)
- **bump**: tag not pushed
- **cz-bump**: minor tweak to create a tag and update the cz toml file
- **deps**: update quarkus platform updates to v3.29.2 (#61)
- **deps**: update dependency io.quarkus:quarkus-bom to v3.29.1 (#60)
- **deps**: update aws sdk v2 monorepo to v2.37.5 (#58)
- **gha**: missing secrets read for integration test
- **config**: migrate config renovate.json (#57)
- **config**: migrate config renovate.json (#56)
- **cognito**: suppress Cognito verification emails on registration
- **deps**: update quarkus platform updates to v3.29.0 (#52)
- **deps**: update aws sdk v2 monorepo to v2.37.3 (#51)
- **deps**: update dependency org.projectlombok:lombok to v1.18.42 (#43)
- **renovate**: trust policy bug fix; also disabling hygiene checks for renovate as pointless
- **gha**: invalid configuration
- **renovate**: trust policy bug fix; also disabling hygiene checks for renovate as pointless
- **renovate**: trust policy bug fix; also disabling hygiene checks for renovate as pointless
- **renovate**: trust policy bug fix; also disabling hygiene checks for renovate as pointless
- **gha**: refining triggers
- **gha**: path install issue
- **secrets**: Removing secrets from docker compose file
- **cron**: Change the janitor GHA job to daily runs rather than every 15 mins now it's working
- **deps**: update dependency com.c4-soft.springaddons:spring-addons-starter-oidc to v8.1.2
- **frontend**: Encrypted yaml file was being included in the .war file classpath
- **mvn**: Maven enforcer plugin impl
- **pr**: Merge branch 'main' of github.com:aeells/bravo-mono
- **ci**: Missing step id referenced in artifact upload output
- **gha**: Reverting.
- **gha**: Trying reusable services workflow again.
- **gha**: Trying reusable services workflow again.
- **gha**: Path incorrect.
- **gha**: Path incorrect.
- **gha**: Reverting.
- **gha**: Splitting out jobs.
- **dependabot**: Merge dependabot PRs.
- **deps**: update dependency org.springdoc:springdoc-openapi-starter-webmvc-ui to v2.8.4
- **deps**: update dependency com.c4-soft.springaddons:spring-addons-starter-oidc to v8.1.1
- **gha**: mvn target fixes.
- **gha**: Combining jobs.
- **gha**: Adding job dependency.
- **gha**: Simplifying mvn commands and job configuration.
- **gha**: Incorrect action configuration.
- **gha**: Repo owner missing.
- **gha**: Refactoring from GHA shared workflow --> action.
- **gha**: Fix to path specs.
- **gha**: Refactoring multi-module GHA impl.
- **sops**: SOPS failing, might be incorrect GHA config.
- **sops**: SOPS failing, as ssl config required dependency.
- **gha**: This should fix the SOPS issue with GHA; services now secured however so curl broken and need to reimplement security properly (JWT maybe).
- **gha**: GHA config for frontend.
- **gha**: GHA config for frontend.
- **sops**: SOPS failing, might be due to dependency.
- **sops**: SOPS now working locally (mac) alongside GHA impl.
- **gha**: Formatting.
- **gha**: Trying simple bash command over sops exec action.
- **gha**: Default sops.yaml config file not found.
- **gha**: Dir path.
- **gha**: Dir path.
- **gha**: Formatting.
- **gha**: Formatting.
- **gha**: Formatting.
- **deps**: renovate merge request.
- **deps**: update dependency org.springframework.boot:spring-boot-starter-parent to v3.4.2
- **sops**: GitHub Actions needs sops installed.
- **sops**: GitHub Actions needs sops installed.
- **xss**: XSS impl - commented out until auth also implemented.
- **gha**: Improved name of build workflow.

### Refactor

- **bff**: align subscription status with actorId
- consume backbone-kit (io.backbone coords, packages, config)
- **aws**: resolve region via SDK provider chain
- **build**: align Maven POMs with best-practice structure
- **config**: reshape platform-config around baseline and environments
- **infra**: align jest domain fixtures with forgeplatform.software
- keep domainRoot on forgeplatform until backbonehq.io is ready
- **test**: restore IT service-test seed under seed/it
- **infra**: keep sibling marketing-site repo references as forge-site
- **infra**: rebrand infrastructure, scripts and CI to Backbone
- **core**: rebrand Forge platform code to Backbone
- **infra**: use cdk deploy --express --rollback flags to speed up DEV/INT CFN deployments
- **clean-up**: minor gha workflow naming; migrated ROADMAP to Linear app; minor offline script bug
- **taskfile**: focusing recent taskfile descriptions
- **bloat**: Cursor adding bloat when simplest action is to teardown and rebuild
- **utils**: consolidate infra utils by AWS resource and Forge stage
- **bash**: add validate_dependencies to test seed scripts
- **bash**: align grafana config and helpers with module template
- **bash**: align metrics scripts with template conventions
- **bash**: add Main section separator before main() entrypoints
- **bash**: wrap Quarkus container entrypoint in main()
- **bash**: standardize perf scripts layout to template conventions
- **bash**: standardize scripts/licence layout to template conventions
- **bash**: standardize .github/scripts layout to template conventions
- **bash**: standardize port-manager and scripts/test layout
- **bash**: align common.sh with module template layout
- **bash**: standardize scripts/docker layout to template conventions
- **bash**: standardize scripts/aws layout to template conventions
- **bash**: standardize script templates and bootstrap layout
- **bash**: polish portability follow-ups across scripts
- **bash**: fixing remaining concerns and removing continue-on-error: true from CI hygience check gate
- **bash**: cleanup of required cli tools approach
- **scripts**: consolidate update_envrc_key in common.sh
- **nvm**: removing proliferation of fixed nvm use directive; only required for infra module
- **cache**: stripping registration endpoint cache support which was prep never implemented - reg insert is cache-aside
- **infra**: migrating hibernate to aws cli to avoid cdk/npx build/synth as latter is subject to drift
- **infra**: ditto missing secret
- **infra**: missing secrets for infra hibernate workflow
- **infra**: dropping IPv6 prefix-list ingress rules as unneccessary
- **infra**: fix to Jest ESM dependency chain which failed tests
- **infra**: mirror Cognito client secrets and tier log retention
- **infra**: CognitoIdp stack drift in relation to Lambda log groups - defining explicitly to counter
- **infra**: removing type-check of every test file in cdk tests
- **infra**: removed dormant port 80 listener on public ALB; historical throwback that was redirecting to 443, no longer needed since CloudFront edge routing refactor
- **infra**: Excluding cdk.context.json from forge-platform mirror fork
- **infra**: Restrict ingest ALB SG to CloudFront prefix lists
- **infra**: Remove orphaned regional WAF
- **cdk**: migrate the ECS toggle to full tear-down of cost-heavy stacks to optmise AWS spend in non-prod envs
- **comments**: explanatory lifecycle tier comments
- **cdk**: split stack termination protection from state concerns
- **cdk**: GH role needs CloudFront permissions to invalidate the distribution on redeployment of the static frontend
- **cdk**: static site S3 bucket policies
- **cdk**: CloudFront standard logging still writes to S3 using ACLs; need to change bucket object ownership
- **cdk**: cross-region refs required for DomainStack
- **cdk**: dependencies do need to be declarative as they were before, introduced a bug by removing
- **cdk**: us-east-1 needs to be bootstrapped
- **cdk**: splitting global CloudFront stack provisioning
- **test**: inconsistent test target fix
- **test**: seed test data cleanup; clarified the control surface and refactored based on different test data lifecycles
- **taskfile**: naming conventions drifted a bit; realigning
- **perf**: reducing collision risk on user email generation for performance tests to negligible
- **perf**: reducing noisy EC2 instance provisioning script output
- **perf**: just breaking up the perf load generator script to aws-specific resource helpers for maintenance
- **perf**: supporting test users / cleanup in AWS proper
- **perf**: cleaning up on seed test data configuration
- **infra**: cost optimisation; reducing AZ count to mirror ECS task count
- **rename**: slight tweak to task name to indicate not exposed
- **rename**: backend-actor renamed more accurately to actor-bff (audience-function)
- **OAuth2**: Made LinkedIn authentication an optional configuration for clients
- **cleanup**: error handling cleanup on failed auth; just reducing noisy logs
- **auth**: password validation in dto tier to reflect cognito
- **github**: repository org transfer
- **tools**: moving toolchain install from README to taskfile
- **cleanup**: todo's removed, esp those where we had messy frontend app leakage
- **rename**: scripts/init --> scripts/bootstrap only
- **config**: moved aws region out of properties file to dedicated client platform config
- **typo**: fixed
- **region**: AWS region and account id are now GitHub Repository variables leaving aws.properties as only other single source of truth
- **chore**: minor cleanup only
- **naming**: consolidating the internal ALB paths as now all the same (suffix removed) and renaming for consistency/clarity
- **client**: removing need for window.location.origin in client web as felt flaky
- **postgres**: cleaned up postgres db name and configuration
- **infra**: migrating GHA role and permissions to CDK
- **gha**: splitting lightweight/heavyweight toolchains so we can be more explicit/optimised in imports to gha workflows
- **infra**: rename/reorg of the infra triggers as infra bootstrap needs to run before build-test so Cognito resources are in place
- **infra**: 01-build-test aws tests now succeed with infra bootstrap / seed resources
- **infra**: aligning LinkedIn secrets/env vars naming convention
- **infra**: retention policy configuration based on stage.
- **infra**: renaming only of infra commands/tasks to separate local cdk from aws deployments
- **cognito**: moved all cognito setup to development CDK stack instead of bash scripts
- **deploy**: all modules and services now deploy to AWS ECS successfully
- **mvn**: making the github deploy token a reusable script for workflow conciseness
- **cleanup**: docs and tidy up really, nothing of note
- **infra**: docs and refactoring of cdklocal taskfile
- **licence**: flipping the licence file to protobuf format and adding version for future compatibility
- **migration**: namespace platform --> core
- **core-package**: moving all libs modules to io.forge.core package structure in advance of releasing
- **audit**: adding ability to plug-in EventBridge dispatcher (and any other) at a later date
- **domain**: deleting domain-related stuff from bravo
- **name**: simple rename
- **notifications**: clean-up of notification-service given high CC and some spotbugs false positives
- **database**: migrate the unsubscribe table from dynamo --> postgres; json was the wrong format
- **oidc**: migrating oidc-related Principal extractors back to forge-platform
- **forge-kit**: all useful interfaces extracted i.e. security etc
- **tidyup**: refactored out another utility (FluentCdiResolver); cleaned up Auth/Token dto utils
- **forge**: further movement towards forge platform brand
- **rename**: web-candidate --> actor
- **rename**: backend-candidate --> actor
- **document-service**: migrating document service from resumes/job specs to standard document storage
- **migration**: migrate rest of JWT-related stuff out to forge-kit
- **spotbugs**: refactoring rename got missed in spotbugs xml file
- **metrics**: migrated metrics out to public repo as open source
- **health**: open-sourcing the health module
- **domain**: renaming candidate --> actor-service
- **domain**: project rename bravo-mono --> forge-platform-core
- **domain**: additional package rename misses io.forge
- **domain**: package refactor tech.eagledrive --> io.forge
- **match-service**: additional matching/match-service references
- **match-service**: dropping match-service as redundant to commercialisation
- **name**: project rename to forge-platform-core
- **static-analysis**: removed pointless logging and exception handling during shutdown handler invocation - was tripping pmd
- **cc**: broken down an untestable StartupServiceInfoPanel class
- **class-name**: AuthUser --> AuthIdentity as it applies to both user/service auth
- **formatting**: minimal code format change only
- **cognito**: migrating cognito configuration to same pattern as elsewhere
- **cc**: major refactor to implement cyclomatic/cognitive complexity thresholds
- **scripts**: just moving helper/sub scripts to named directory leaving orchestrator scripts clear
- **metrics**: minor metrics config tweaks
- **logs**: suppress noisy unit test logs
- **metrics**: bump metrics pom after rebase
- **metrics**: migrating out of common to separate package
- **naming**: standardising parent applications module name (pluralising as per services/libs)
- **metrics**: migrated from intrusive boilerplate to cross-cutting concern
- **IAM-fix-for-CI-tests**: also some minor code cleanup
- **cognito**: split user pool out into candidate|client|service user pools for security and configuration reasons
- **stateless**: major refactor of the security architecture to go fully stateless
- **naming**: module rename to security-web
- **cleanup**: removal of a bunch of WARN messages etc. nothing functional
- **domain**: consolidating multiple client modules
- **namespace**: package namespace standardisation as per docs/architecture/package-structure-analysis.md
- **auth**: namespace and cleanup of AuthUser in light of ADR 0009
- **namespace**: application/ui module namespace reservations
- **dotenv**: replaced .env approach with simpler .envrc and direnv approach
- **naming**: migrate backend --> services namespace
- **fixes**: slight mods given the recent refactor to get integration tests passing
- **match**: adding match-service skeleton to index and match resumes <--> job specs
- **cleanup**: deleting old code/thought processes
- **scripts**: moving all bash scripts and deleting .config dir as misnamed
- **naming**: refactoring the module and packages to parser-service; wraps both textkernel and dummy service impls
- **textkernel**: refactoring naming conventions prior to adding further impl (job parsing)
- **lefthook**: simplifying and removing the need to run mvn verify if no relevant files changed (rudimentary impl but better than before)
- **auth**: skipping Cognito Identity Pool auth
- **tests**: moving auth tests to security lib
- **maven**: pinning mvnd and mvnw to same version (via ~/.zshrc MVND_MAVEN_HOME)
- **maven**: compliancy fix
- clean up
- **Removing-SpringBoot**: Removing SpringBoot dependencies etc with the intent of replacing with Quarkus

### Perf

- **ci**: drop ui/template from install; remove taskfile.ci.yml
- **ci**: skip quarkus:build during install for test workflows
- **ci**: run Failsafe ITs without package/quarkus:build
- **ci**: run integration tests without -am after artifact restore
- **ci**: use Temurin for non-native workflows
- **ci**: use Temurin instead of GraalVM for build-test
- **ci**: split integration tests into auth and rest jobs
- **auth**: nest Cognito user/service ITs under one Quarkus boot
- **test**: cut Quarkus IT boots for notification and document
- **ci**: drop IT timing summary and skip template-service ITs
- **ci**: parallelize integration tests with Maven -T
- **tuning**: testing with 2 count of ECS instances and think we are seeing datasource connection pool exhaustion
- **tuning**: connection pool tuning for http and db at 200 VUs
- **ttl**: recycling pooled connections before a internal ALB idle timeout (60s)
- **quarkus**: graceful shutdown config
- **jvm**: Replacing Tomcat with Undertow; jvm and build optimisations
