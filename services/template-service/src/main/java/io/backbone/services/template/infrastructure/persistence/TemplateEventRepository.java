package io.backbone.services.template.infrastructure.persistence;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import jakarta.transaction.Transactional;

/**
 * Repository for template example event persistence in PostgreSQL.
 */
@ApplicationScoped
public class TemplateEventRepository
{
    private final EntityManager entityManager;

    @Inject
    public TemplateEventRepository(final EntityManager entityManager)
    {
        this.entityManager = entityManager;
    }

    @Transactional
    public void save(final TemplateEventRecord record)
    {
        entityManager.persist(record);
    }
}
