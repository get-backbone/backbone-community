package io.backbone.application.backend.infrastructure;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.List;
import java.util.Map;
import org.eclipse.microprofile.openapi.OASFactory;
import org.eclipse.microprofile.openapi.models.OpenAPI;
import org.junit.jupiter.api.Test;

final class ReadMeOpenApiFilterTest
{
    @Test
    void publishesReadMeServerAndExtensionsWithoutReplacingTags()
    {
        final OpenAPI openAPI = OASFactory.createOpenAPI();
        openAPI.setTags(List.of(OASFactory.createTag().name("Actors"), OASFactory.createTag().name("Actor Auth")));

        new ReadMeOpenApiFilter().filterOpenAPI(openAPI);

        assertEquals(List.of("https://int.backbonehq.io"), openAPI.getServers().stream().map(server -> server.getUrl()).toList());
        assertEquals(List.of("Actors", "Actor Auth"), openAPI.getTags().stream().map(tag -> tag.getName()).toList());

        @SuppressWarnings("unchecked") final Map<String, Object> readme = (Map<String, Object>) openAPI.getExtensions().get("x-readme");
        assertEquals(false, readme.get("explorer-enabled"));
        assertEquals(true, readme.get("apply-tag-changes"));
        assertEquals(true, readme.get("apply-endpoint-order"));
    }
}
