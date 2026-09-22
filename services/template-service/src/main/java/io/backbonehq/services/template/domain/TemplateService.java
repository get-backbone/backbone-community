package io.backbonehq.services.template.domain;

import io.backbonehq.core.audit.api.domain.AuditEvent;
import io.backbonehq.core.audit.api.domain.EventSeverity;
import io.backbonehq.core.audit.api.domain.EventType;
import io.backbonehq.kit.logging.api.LogMethodEntry;
import io.backbonehq.kit.metrics.api.domain.ServiceMetrics;
import io.backbonehq.services.template.domain.dto.TemplateEventRequest;
import io.backbonehq.services.template.domain.dto.TemplateEventResponse;
import io.backbonehq.services.template.infrastructure.TemplateEventMapper;
import io.backbonehq.services.template.infrastructure.TemplateMetricsRecorder;
import io.backbonehq.services.template.infrastructure.persistence.TemplateEventRecord;
import io.backbonehq.services.template.infrastructure.persistence.TemplateEventRepository;
import io.opentelemetry.instrumentation.annotations.WithSpan;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

/**
 * Domain service for the template example flow with RDS persistence.
 */
@ApplicationScoped
public class TemplateService
{
    private final TemplateEventRepository templateEventRepository;

    private final TemplateEventMapper templateEventMapper;

    @Inject
    public TemplateService(final TemplateEventRepository templateEventRepository, final TemplateEventMapper templateEventMapper)
    {
        this.templateEventRepository = templateEventRepository;
        this.templateEventMapper = templateEventMapper;
    }

    /**
     * Processes and persists a template example event.
     *
     * @param request the event payload
     * @return accepted response mirroring the event id
     */
    @WithSpan
    @ServiceMetrics(TemplateMetricsRecorder.class)
    @LogMethodEntry(message = "for event: %s", argPaths = {"#eventId"})
    @AuditEvent(message = "Template event: %s", argPaths = {"#eventId"}, type = EventType.DATA_ACCESS, severity = EventSeverity.INFO)
    public TemplateEventResponse processEvent(final TemplateEventRequest request)
    {
        final TemplateEventRecord record = templateEventMapper.toRecord(request);
        templateEventRepository.save(record);

        return TemplateEventResponse.accepted(request.getEventId());
    }
}
