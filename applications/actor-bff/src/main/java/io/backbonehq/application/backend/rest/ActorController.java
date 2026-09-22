package io.backbonehq.application.backend.rest;

import io.backbonehq.core.client.api.actor.ActorServiceClient;
import io.backbonehq.core.domain.dto.actor.ActorResponse;
import io.backbonehq.kit.security.api.rest.Secured;
import io.opentelemetry.instrumentation.annotations.WithSpan;
import io.quarkus.hal.HalEntityWrapper;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.Link;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.Map;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;
import org.eclipse.microprofile.rest.client.inject.RestClient;
import org.jboss.logging.Logger;
import org.jboss.resteasy.reactive.ClientWebApplicationException;

/**
 * REST controller for actor operations.
 * This endpoint is called by authenticated users to retrieve their actor profile.
 */
@Path("/actors")
@Tag(name = "Actors")
@Produces({MediaType.APPLICATION_JSON, "application/hal+json"})
@Consumes(MediaType.APPLICATION_JSON)
public final class ActorController
{
    private static final Logger LOGGER = Logger.getLogger(ActorController.class);

    private final ActorServiceClient actorServiceClient;

    @Inject
    ActorController(@RestClient final ActorServiceClient actorServiceClient)
    {
        this.actorServiceClient = actorServiceClient;
    }

    @GET
    @WithSpan
    @Secured
    @Path("/{actorId}")
    @Operation(summary = "Get profile")
    public Response getActor(@PathParam("actorId") final String actorId)
    {
        try
        {
            try (final Response upstream = actorServiceClient.getActor(actorId))
            {
                if (upstream.getStatus() != Response.Status.OK.getStatusCode())
                {
                    return Response.status(upstream.getStatus())
                        .entity(Map.of("error", "Failed to retrieve actor"))
                        .build();
                }

                final ActorResponse actor = upstream.readEntity(ActorResponse.class);
                return Response.ok(toHal(actor)).build();
            }
        }
        catch (final ClientWebApplicationException e)
        {
            final int statusCode = getStatusCode(e);
            if (statusCode == Response.Status.NOT_FOUND.getStatusCode())
            {
                // 404 is a valid response - actor doesn't exist
                LOGGER.warnf("Actor not found: %s", actorId);
                return getErrorResponse(Response.Status.NOT_FOUND.getStatusCode(), "Actor not found");
            }

            // For other error statuses, log and return the error
            LOGGER.errorf("Error retrieving actor %s: status %d", actorId, statusCode);
            return getErrorResponse(statusCode, "Failed to retrieve actor");
        }
    }

    private static HalEntityWrapper<ActorResponse> toHal(final ActorResponse actor)
    {
        final Link[] links = ActorProfileLinks.forActor(actor).toArray(Link[]::new);
        return new HalEntityWrapper<>(actor, links);
    }

    private static int getStatusCode(final ClientWebApplicationException e)
    {
        return e.getResponse() != null ? e.getResponse().getStatus() : Response.Status.INTERNAL_SERVER_ERROR.getStatusCode();
    }

    private static Response getErrorResponse(final int statusCode, final String errorMessage)
    {
        return Response.status(statusCode)
            .entity(Map.of("error", errorMessage))
            .build();
    }
}
