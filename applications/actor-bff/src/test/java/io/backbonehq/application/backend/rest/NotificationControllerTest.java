package io.backbonehq.application.backend.rest;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.*;

import io.backbonehq.core.client.api.actor.ActorServiceClient;
import io.backbonehq.core.client.api.notification.NotificationServiceClient;
import io.backbonehq.core.domain.dto.actor.ActorResponse;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Response;
import java.time.Instant;
import org.jboss.resteasy.reactive.ClientWebApplicationException;
import org.junit.jupiter.api.Test;

final class NotificationControllerTest
{
    private final ActorServiceClient actorServiceClient = mock(ActorServiceClient.class);

    private final NotificationServiceClient notificationServiceClient = mock(NotificationServiceClient.class);

    private final NotificationController notificationController = new NotificationController(actorServiceClient, notificationServiceClient);

    @Test
    void getSubscriptionStatusRequiresActorId()
    {
        final WebApplicationException exception = assertThrows(
            WebApplicationException.class, () -> notificationController.getSubscriptionStatus(null, null)
        );

        assertEquals(Response.Status.BAD_REQUEST.getStatusCode(), exception.getResponse().getStatus());
        verifyNoInteractions(actorServiceClient, notificationServiceClient);
    }

    @Test
    void getSubscriptionStatusResolvesEmailThenProxies()
    {
        final ActorResponse actor = ActorResponse.success(
            "actor-1", "user@example.com", "User", null, null, null, Instant.parse("2026-01-01T00:00:00Z")
        );
        when(actorServiceClient.getActor("actor-1")).thenReturn(Response.ok(actor).build());

        final Response expected = Response.ok().build();
        when(notificationServiceClient.getSubscriptionStatus("user@example.com", "EMAIL")).thenReturn(expected);

        final Response actual = notificationController.getSubscriptionStatus("actor-1", "EMAIL");

        assertEquals(expected, actual);
        verify(actorServiceClient).getActor("actor-1");
        verify(notificationServiceClient).getSubscriptionStatus("user@example.com", "EMAIL");
    }

    @Test
    void getSubscriptionStatusReturnsNotFoundWhenActorMissing()
    {
        when(actorServiceClient.getActor("missing")).thenThrow(
            new ClientWebApplicationException(Response.status(Response.Status.NOT_FOUND).build())
        );

        final WebApplicationException exception = assertThrows(
            WebApplicationException.class, () -> notificationController.getSubscriptionStatus("missing", null)
        );

        assertEquals(Response.Status.NOT_FOUND.getStatusCode(), exception.getResponse().getStatus());
        verifyNoInteractions(notificationServiceClient);
    }
}
