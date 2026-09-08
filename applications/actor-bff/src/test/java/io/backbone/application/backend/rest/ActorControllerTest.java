package io.backbone.application.backend.rest;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import io.backbone.core.client.api.actor.ActorServiceClient;
import io.backbone.core.domain.dto.actor.ActorResponse;
import io.quarkus.hal.HalEntityWrapper;
import jakarta.ws.rs.core.Response;
import java.time.Instant;
import org.jboss.resteasy.reactive.ClientWebApplicationException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

final class ActorControllerTest
{
    private ActorServiceClient actorServiceClient = mock(ActorServiceClient.class);

    private ActorController actorController;

    @BeforeEach
    void setUp()
    {
        actorController = new ActorController(actorServiceClient);
    }

    @Test
    @DisplayName("getActor wraps successful profile in HAL with link-linkedin when unlinked")
    void getActor_ReturnsHalWrapperWithLinkLinkedIn()
    {
        final ActorResponse actor = ActorResponse.success("actor-1", "ada@example.com", "Ada", null, null, null, Instant
            .parse("2026-01-01T00:00:00Z"));
        when(actorServiceClient.getActor("actor-1")).thenReturn(Response.ok(actor).build());

        final Response response = actorController.getActor("actor-1");

        assertEquals(Response.Status.OK.getStatusCode(), response.getStatus());
        @SuppressWarnings("unchecked") final HalEntityWrapper<ActorResponse> wrapper = assertInstanceOf(HalEntityWrapper.class, response.getEntity());
        assertEquals(actor, wrapper.getEntity());
        assertTrue(wrapper.getLinks().containsKey("self"));
        assertTrue(wrapper.getLinks().containsKey("documents"));
        assertTrue(wrapper.getLinks().containsKey("complete-linkedin-link"));
        assertTrue(wrapper.getLinks().containsKey("link-linkedin"));
    }

    @Test
    @DisplayName("getActor omits link-linkedin when already linked")
    void getActor_OmitsLinkLinkedInWhenLinked()
    {
        final ActorResponse actor = ActorResponse.success("actor-1", "ada@example.com", "Ada", "linkedin-sub", null, null, Instant
            .parse("2026-01-01T00:00:00Z"));
        when(actorServiceClient.getActor("actor-1")).thenReturn(Response.ok(actor).build());

        final Response response = actorController.getActor("actor-1");

        @SuppressWarnings("unchecked") final HalEntityWrapper<ActorResponse> wrapper = assertInstanceOf(HalEntityWrapper.class, response.getEntity());
        assertTrue(wrapper.getLinks().containsKey("self"));
        assertTrue(wrapper.getLinks().containsKey("complete-linkedin-link"));
        assertFalse(wrapper.getLinks().containsKey("link-linkedin"));
    }

    @Test
    @DisplayName("getActor maps upstream 404 to not found")
    void getActor_MapsNotFound()
    {
        final ClientWebApplicationException notFound = mock(ClientWebApplicationException.class);
        when(notFound.getResponse()).thenReturn(Response.status(Response.Status.NOT_FOUND).build());
        when(actorServiceClient.getActor("missing")).thenThrow(notFound);

        final Response response = actorController.getActor("missing");

        assertEquals(Response.Status.NOT_FOUND.getStatusCode(), response.getStatus());
    }
}
