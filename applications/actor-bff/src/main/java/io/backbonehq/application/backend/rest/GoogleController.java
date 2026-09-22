package io.backbonehq.application.backend.rest;

import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.core.Response;
import java.net.URI;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

/**
 * Proxies Google OAuth2 login initiation to auth-service.
 */
@Path("/auth")
@Tag(name = "Provider Auth")
public final class GoogleController
{
    private final String authServiceUrl;

    @Inject
    public GoogleController(@ConfigProperty(name = "quarkus.rest-client.AuthServiceClient.url") final String authServiceUrl)
    {
        this.authServiceUrl = authServiceUrl;
    }

    @GET
    @Path("/google/login")
    @Operation(summary = "Google login (redirect)", operationId = "googleLogin")
    public Response login()
    {
        final String baseUrl = authServiceUrl.endsWith("/") ? authServiceUrl.substring(0, authServiceUrl.length() - 1) : authServiceUrl;

        return Response.seeOther(URI.create(baseUrl + "/auth/google/login")).build();
    }
}
