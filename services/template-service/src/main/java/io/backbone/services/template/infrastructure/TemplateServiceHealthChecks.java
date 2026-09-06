package io.backbone.services.template.infrastructure;

import io.backbone.kit.health.impl.infrastructure.PostgresHealthCheck;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;
import jakarta.persistence.EntityManager;
import java.util.List;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.eclipse.microprofile.health.HealthCheck;
import org.eclipse.microprofile.health.Readiness;

/**
 * Registers health checks for template-service (RDS / Postgres).
 */
@ApplicationScoped
public class TemplateServiceHealthChecks
{
    @Produces
    @Readiness
    @ApplicationScoped
    public HealthCheck postgresTemplateEventsTableHealthCheck(final EntityManager entityManager, @ConfigProperty(name = "backbone.postgres.database-name") final String databaseName)
    {
        return new PostgresHealthCheck(entityManager, databaseName, List.of("template_events"))
        {
        };
    }
}
