package io.backbonehq.application.backend.infrastructure;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;

import java.util.List;
import java.util.Map;
import org.eclipse.microprofile.openapi.OASFactory;
import org.eclipse.microprofile.openapi.models.OpenAPI;
import org.junit.jupiter.api.Test;

final class ReadMeOpenApiFilterTest
{
    @Test
    void filterOpenAPI_keepsReadmeKeyOrder()
    {
        final OpenAPI openAPI = OASFactory.createOpenAPI();

        new ReadMeOpenApiFilter().filterOpenAPI(openAPI);

        final Map<?, ?> readme = assertInstanceOf(Map.class, openAPI.getExtensions().get("x-readme"));

        assertEquals(List.of("explorer-enabled", "apply-endpoint-order", "apply-tag-changes"), List.copyOf(readme.keySet()));
    }
}
