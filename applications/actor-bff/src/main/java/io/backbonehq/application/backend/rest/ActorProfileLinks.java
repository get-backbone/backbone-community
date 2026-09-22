package io.backbonehq.application.backend.rest;

import io.backbonehq.core.domain.dto.actor.ActorResponse;
import jakarta.ws.rs.core.Link;
import jakarta.ws.rs.core.UriBuilder;
import java.util.ArrayList;
import java.util.List;
import org.apache.commons.lang3.StringUtils;

/**
 * Builds HAL link affordances for an actor profile resource.
 */
final class ActorProfileLinks
{
    private static final String REL_SELF = "self";

    private static final String REL_DOCUMENTS = "documents";

    private static final String REL_LINKEDIN_CONNECT = "linkedin-connect";

    private static final String REL_COMPLETE_LINKEDIN_CONNECT = "complete-linkedin-connect";

    private ActorProfileLinks()
    {
    }

    static List<Link> forActor(final ActorResponse actor)
    {
        final String actorId = actor.actorId();
        final List<Link> links = new ArrayList<>(4);

        links.add(Link.fromPath("/actors/{actorId}").rel(REL_SELF).build(actorId));
        links.add(Link.fromUri(
            UriBuilder.fromPath("/documents").queryParam("actorId", actorId).build()
        ).rel(REL_DOCUMENTS).build());
        links.add(Link.fromPath("/auth/linkedin/connect/complete").rel(REL_COMPLETE_LINKEDIN_CONNECT).build());

        if (StringUtils.isBlank(actor.linkedInSub()))
        {
            links.add(Link.fromPath("/auth/linkedin/connect").rel(REL_LINKEDIN_CONNECT).build());
        }

        return links;
    }
}
