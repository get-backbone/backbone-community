package io.backbone.services.template.infrastructure;

import io.backbonehq.kit.metrics.api.domain.MetricsRecorder;
import io.backbonehq.kit.metrics.api.dto.MetricsResultIndicator;
import io.backbonehq.kit.metrics.impl.domain.support.MetricsTagSanitizer;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.interceptor.InvocationContext;

/**
 * Metrics recorder for template operations.
 * Records processing success/failure metrics for domain methods annotated with {@code @ServiceMetrics}.
 *
 * <p>The operation name (method name) is automatically extracted by the interceptor.
 */
@ApplicationScoped
public final class TemplateMetricsRecorder implements MetricsRecorder
{
    @Inject
    MeterRegistry meterRegistry;

    @Override
    public void recordMetrics(final InvocationContext context, final MetricsResultIndicator metricsResultIndicator)
    {
        final String operation = context.getMethod().getName();

        if (metricsResultIndicator == null || metricsResultIndicator.success())
        {
            recordProcessingSuccess(operation);
        }
        else
        {
            recordProcessingFailure(operation, metricsResultIndicator.errorMessage());
        }
    }

    @Override
    public void recordException(final InvocationContext context, final Exception exception)
    {
        final String operation = context.getMethod().getName();
        final String exceptionType = exception.getClass().getSimpleName();
        recordProcessingFailure(operation, "exception: " + exceptionType);
    }

    private void recordProcessingSuccess(final String operation)
    {
        Counter.builder("template.processing")
            .tag("operation", operation)
            .tag("status", "success")
            .description("Template processing events")
            .register(meterRegistry)
            .increment();
    }

    private void recordProcessingFailure(final String operation, final String reason)
    {
        Counter.builder("template.processing")
            .tag("operation", operation)
            .tag("status", "failure")
            .tag("reason", MetricsTagSanitizer.sanitize(reason))
            .description("Template processing events")
            .register(meterRegistry)
            .increment();
    }
}
