package io.backbonehq.application.backend.rest;

import io.backbonehq.core.client.api.actor.ActorServiceClient;
import io.backbonehq.core.client.api.notification.NotificationServiceClient;
import io.backbonehq.core.domain.dto.actor.ActorResponse;
import io.backbonehq.kit.security.api.rest.Secured;
import io.opentelemetry.instrumentation.annotations.WithSpan;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.Map;
import org.apache.commons.lang3.StringUtils;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;
import org.eclipse.microprofile.rest.client.inject.RestClient;
import org.jboss.resteasy.reactive.ClientWebApplicationException;

/**
 * REST controller for notification subscription operations.
 * Resolves the actor email via actor-service, then proxies to notification-service.
 */
@Path("/notifications")
@Tag(name = "Notifications")
@Produces(MediaType.APPLICATION_JSON)
public final class NotificationController
{
    private final ActorServiceClient actorServiceClient;

    private final NotificationServiceClient notificationServiceClient;

    @Inject
    public NotificationController(@RestClient final ActorServiceClient actorServiceClient, @RestClient final NotificationServiceClient notificationServiceClient)
    {
        this.actorServiceClient = actorServiceClient;
        this.notificationServiceClient = notificationServiceClient;
    }

    @GET
    @WithSpan
    @Secured
    @Path("/subscriptions")
    @Operation(summary = "Get subscription status")
    public Response getSubscriptionStatus(@QueryParam("actorId") final String actorId, @QueryParam("channel") final String channel)
    {
        requireActorId(actorId);
        return notificationServiceClient.getSubscriptionStatus(resolveActorEmail(actorId), channel);
    }

    private String resolveActorEmail(final String actorId)
    {
        try (Response actorResponse = actorServiceClient.getActor(actorId))
        {
            final ActorResponse actor = actorResponse.readEntity(ActorResponse.class);
            if (actor == null || StringUtils.isEmpty(actor.emailAddress()))
            {
                throw badRequest("Actor email is unavailable");
            }
            return actor.emailAddress();
        }
        catch (final ClientWebApplicationException e)
        {
            throw mapActorLookupFailure(e);
        }
    }

    private static WebApplicationException mapActorLookupFailure(final ClientWebApplicationException e)
    {
        final int status = e.getResponse() != null ? e.getResponse().getStatus() : Response.Status.INTERNAL_SERVER_ERROR.getStatusCode();

        if (status == Response.Status.NOT_FOUND.getStatusCode())
        {
            return errorResponse(Response.Status.NOT_FOUND.getStatusCode(), "Actor not found");
        }

        return errorResponse(status, "Failed to resolve actor");
    }

    private static void requireActorId(final String actorId)
    {
        if (StringUtils.isEmpty(actorId))
        {
            throw badRequest("actorId is required");
        }
    }

    private static WebApplicationException badRequest(final String message)
    {
        return errorResponse(Response.Status.BAD_REQUEST.getStatusCode(), message);
    }

    private static WebApplicationException errorResponse(final int statusCode, final String message)
    {
        return new WebApplicationException(
            Response.status(statusCode)
                .entity(Map.of("error", message))
                .build()
        );
    }
}
