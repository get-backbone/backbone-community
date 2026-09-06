package io.backbone.services.template.infrastructure;

import static java.util.Objects.requireNonNull;

import io.backbone.services.template.domain.dto.TemplateEventRequest;
import io.backbone.services.template.infrastructure.persistence.TemplateEventRecord;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.Instant;

/**
 * Maps template example request DTOs to persistence records.
 */
@ApplicationScoped
public final class TemplateEventMapper
{
    public TemplateEventRecord toRecord(final TemplateEventRequest request)
    {
        requireNonNull(request, "request cannot be null");

        final TemplateEventRecord record = new TemplateEventRecord();
        record.setEventId(request.getEventId());
        record.setMessage(request.getMessage());
        record.setCreatedAt(Instant.now());

        return record;
    }
}
