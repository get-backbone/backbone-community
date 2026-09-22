package io.backbonehq.application.backend.rest;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;

import io.backbonehq.core.domain.dto.actor.ActorResponse;
import jakarta.ws.rs.core.Link;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

final class ActorProfileLinksTest
{
    @Test
    @DisplayName("unlinked actor includes linkedin-connect affordance")
    void forActor_IncludesLinkLinkedInWhenUnlinked()
    {
        final ActorResponse actor = ActorResponse.success("actor-1", "ada@example.com", "Ada", null, "google-sub", null, Instant
            .parse("2026-01-01T00:00:00Z"));

        final Map<String, String> hrefs = hrefsByRel(ActorProfileLinks.forActor(actor));

        assertEquals("/actors/actor-1", hrefs.get("self"));
        assertEquals("/documents?actorId=actor-1", hrefs.get("documents"));
        assertEquals("/auth/linkedin/connect/complete", hrefs.get("complete-linkedin-connect"));
        assertEquals("/auth/linkedin/connect", hrefs.get("linkedin-connect"));
    }

    @Test
    @DisplayName("linked actor omits linkedin-connect affordance")
    void forActor_OmitsLinkLinkedInWhenLinked()
    {
        final ActorResponse actor = ActorResponse.success("actor-1", "ada@example.com", "Ada", "linkedin-sub", "google-sub", null, Instant
            .parse("2026-01-01T00:00:00Z"));

        final Map<String, String> hrefs = hrefsByRel(ActorProfileLinks.forActor(actor));

        assertEquals("/actors/actor-1", hrefs.get("self"));
        assertEquals("/documents?actorId=actor-1", hrefs.get("documents"));
        assertEquals("/auth/linkedin/connect/complete", hrefs.get("complete-linkedin-connect"));
        assertFalse(hrefs.containsKey("linkedin-connect"));
    }

    private static Map<String, String> hrefsByRel(final List<Link> links)
    {
        return links.stream().collect(Collectors.toMap(Link::getRel, link -> link.getUri().toString()));
    }
}
