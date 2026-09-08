package io.backbone.services.template.rest;

import io.backbone.core.security.api.rest.AbstractRestResource;
import io.backbone.kit.security.api.rest.AllowedServices;
import io.backbone.services.template.domain.TemplateService;
import io.backbone.services.template.domain.dto.TemplateEventRequest;
import io.opentelemetry.instrumentation.annotations.WithSpan;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

/**
 * Example REST resource for scaffolded services.
 * POST /template/events accepts a single event and returns 201 when accepted.
 */
@Path("/template")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@SuppressWarnings("unused")
public final class TemplateResource extends AbstractRestResource
{
    private final TemplateService templateService;

    @Inject
    public TemplateResource(final TemplateService templateService)
    {
        this.templateService = templateService;
    }

    /**
     * Ingests a template example event.
     * {@code @AllowedServices} lists example callers; replace with real callers after scaffolding.
     *
     * @param request the event payload
     * @return 201 when accepted
     */
    @POST
    @Path("/events")
    @WithSpan
    @AllowedServices({"auth-service"})
    public Response ingestEvent(@Valid final TemplateEventRequest request)
    {
        return execute(() ->
        {
            templateService.processEvent(request);
            return Response.status(Response.Status.CREATED).build();
        }, "Template event failed");
    }
}
