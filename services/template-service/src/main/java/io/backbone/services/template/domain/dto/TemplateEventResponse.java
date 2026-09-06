package io.backbone.services.template.domain.dto;

import io.backbone.kit.metrics.api.dto.MetricsResultIndicator;
import java.util.UUID;
import org.eclipse.microprofile.openapi.annotations.media.Schema;

/**
 * Service-local response DTO for the template example event ingest endpoint.
 *
 * <p>Implements {@link MetricsResultIndicator} so {@code @ServiceMetrics} can record success/failure.
 */
@Schema(description = "Template example event ingest result")
public record TemplateEventResponse(
                                    @Schema(description = "Indicates if the operation was successful", examples = "true") boolean success,
                                    @Schema(description = "Echo of the accepted event identifier") UUID eventId,
                                    @Schema(description = "Error message if the operation failed") String errorMessage
) implements MetricsResultIndicator
{
    /**
     * Creates a successful response for the given event.
     *
     * @param eventId the accepted event identifier
     * @return a successful response
     */
    public static TemplateEventResponse accepted(final UUID eventId)
    {
        return new TemplateEventResponse(true, eventId, null);
    }

    /**
     * Creates a failed response.
     *
     * @param errorMessage the failure reason
     * @return a failed response
     */
    public static TemplateEventResponse failure(final String errorMessage)
    {
        return new TemplateEventResponse(false, null, errorMessage);
    }
}
