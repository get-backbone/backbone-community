package io.backbone.services.template.domain.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.eclipse.microprofile.openapi.annotations.media.Schema;

/**
 * Service-local request DTO for the template example event ingest endpoint.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Template example event payload")
public class TemplateEventRequest
{
    @NotNull
    @Schema(description = "Unique event identifier", required = true)
    private UUID eventId;

    @NotBlank
    @Schema(description = "Event message or payload summary", required = true, examples = "example event")
    private String message;
}
