package io.backbone.application.backend.rest;

import static jakarta.ws.rs.core.HttpHeaders.AUTHORIZATION;
import static java.util.Map.of;

import com.fasterxml.jackson.core.type.TypeReference;
import io.backbone.core.client.api.auth.AuthServiceClient;
import io.backbone.core.common.api.json.JsonFacade;
import io.backbonehq.kit.security.api.rest.Secured;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.Map;
import org.apache.commons.lang3.StringUtils;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;
import org.eclipse.microprofile.rest.client.inject.RestClient;

/**
 * REST controller for LinkedIn OAuth2 endpoints.
 * Proxies LinkedIn login and account connect requests to auth-service.
 */
@Path("/auth/linkedin")
@Tag(name = "Provider Auth")
public final class LinkedInController
{
    @Inject
    @RestClient
    AuthServiceClient authServiceClient;

    @ConfigProperty(name = "quarkus.rest-client.AuthServiceClient.url")
    String authServiceUrl;

    @GET
    @Path("/login")
    @Operation(summary = "LinkedIn login (redirect)", operationId = "linkedInLogin")
    public Response login()
    {
        final String baseUrl = authServiceUrl.endsWith("/") ? authServiceUrl.substring(0, authServiceUrl.length() - 1) : authServiceUrl;

        return Response.seeOther(URI.create(baseUrl + "/auth/linkedin/login")).build();
    }

    @GET
    @Secured
    @Path("/connect")
    @Operation(summary = "Start LinkedIn connect")
    public Response startConnect(final HttpHeaders headers)
    {
        try (final HttpClient client = HttpClient.newBuilder()
            .followRedirects(HttpClient.Redirect.NEVER)
            .build())
        {
            final String authorizationHeader = headers.getHeaderString(AUTHORIZATION);
            if (StringUtils.isEmpty(authorizationHeader))
            {
                return Response.status(Response.Status.UNAUTHORIZED)
                    .entity(of("error", "Authorization header required"))
                    .build();
            }

            final String baseUrl = authServiceUrl.endsWith("/") ? authServiceUrl.substring(0, authServiceUrl.length() - 1) : authServiceUrl;
            final String linkedInConnectUrl = baseUrl + "/auth/linkedin/connect";

            final HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(linkedInConnectUrl))
                .header(AUTHORIZATION, authorizationHeader)
                .GET()
                .build();

            final HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
            final int statusCode = response.statusCode();

            if (statusCode == Response.Status.OK.getStatusCode())
            {
                final String responseBody = response.body();
                final Map<String, Object> jsonResponse = JsonFacade.fromPlainJson(
                    responseBody, new TypeReference<>()
                    {
                    }, "LinkedIn connect response");
                final String authorizationUrl = (String) jsonResponse.get("authorizationUrl");

                if (authorizationUrl != null)
                {
                    return Response.ok()
                        .entity(Map.of("authorizationUrl", authorizationUrl))
                        .build();
                }
            }

            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                .entity(of("error", "Unexpected response from auth-service: HTTP " + statusCode))
                .build();
        }
        catch (final IOException | InterruptedException e)
        {
            return Response.status(Response.Status.BAD_GATEWAY)
                .entity(of("error", "Failed to connect to LinkedIn auth server: " + e.getMessage()))
                .build();
        }
    }

    @POST
    @Path("/connect/complete")
    @Operation(summary = "Finish LinkedIn connect")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response finishConnect(final Map<String, String> request)
    {
        return authServiceClient.completeLinkedInConnect(request);
    }
}
