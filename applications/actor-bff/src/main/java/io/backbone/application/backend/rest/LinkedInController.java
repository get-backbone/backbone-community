package io.backbone.application.backend.rest;

import static jakarta.ws.rs.core.HttpHeaders.AUTHORIZATION;
import static java.util.Map.of;

import com.fasterxml.jackson.core.type.TypeReference;
import io.backbone.core.client.api.auth.AuthServiceClient;
import io.backbone.core.common.api.json.JsonFacade;
import io.backbone.kit.security.api.rest.Secured;
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
 * Proxy LinkedIn login and account linking requests to auth-service, providing a single entry point for frontend clients.
 */
@Path("/auth")
@Tag(name = "Auth")
public final class LinkedInController
{
    @Inject
    @RestClient
    AuthServiceClient authServiceClient;

    @ConfigProperty(name = "quarkus.rest-client.AuthServiceClient.url")
    String authServiceUrl;

    /**
     * Proxy LinkedIn OAuth2 login initiation to auth-service.
     * This endpoint redirects to auth-service's LinkedIn login endpoint, which then redirects to LinkedIn.
     * The OAuth callback will return to auth-service, which handles token exchange and redirects back to the UI.
     *
     * @return Redirect response to auth-service's LinkedIn login endpoint
     */
    @GET
    @Path("/linkedin/login")
    @Operation(summary = "Start LinkedIn login (redirect)", operationId = "linkedInLogin")
    public Response login()
    {
        final String baseUrl = authServiceUrl.endsWith("/") ? authServiceUrl.substring(0, authServiceUrl.length() - 1) : authServiceUrl;

        return Response.seeOther(URI.create(baseUrl + "/auth/linkedin/login")).build();
    }

    /**
     * Proxies LinkedIn OAuth2 account linking initiation to auth-service.
     * This endpoint requires authentication and forwards the request to auth-service with the Authorization header.
     * Auth-service will then redirect to LinkedIn for OAuth authorization.
     *
     * @return Redirect response to LinkedIn authorization endpoint
     */
    @GET
    @Secured
    @Path("/linkedin/link")
    @Operation(summary = "Start LinkedIn account linking")
    public Response linkAccount(final HttpHeaders headers)
    {
        // Use HttpClient to make the request without following redirects
        // This allows us to get the Location header from the redirect response
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

            // Build URL to auth-service's LinkedIn linking endpoint
            final String baseUrl = authServiceUrl.endsWith("/") ? authServiceUrl.substring(0, authServiceUrl.length() - 1) : authServiceUrl;
            final String linkedInLinkUrl = baseUrl + "/auth/linkedin/link";

            final HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(linkedInLinkUrl))
                .header(AUTHORIZATION, authorizationHeader)
                .GET()
                .build();

            final HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
            final int statusCode = response.statusCode();

            // Auth-service now returns the authorization URL in the response body (JSON)
            if (statusCode == Response.Status.OK.getStatusCode())
            {
                final String responseBody = response.body();
                final Map<String, Object> jsonResponse = JsonFacade.fromPlainJson(
                    responseBody, new TypeReference<>()
                    {
                    }, "LinkedIn link response");
                final String authorizationUrl = (String) jsonResponse.get("authorizationUrl");

                if (authorizationUrl != null)
                {
                    // Return the authorization URL in response body for frontend to handle
                    return Response.ok()
                        .entity(Map.of("authorizationUrl", authorizationUrl))
                        .build();
                }
            }

            // If not successful, return error with status code
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

    /**
     * Proxies LinkedIn account linking completion to auth-service.
     * Called by frontend after successful LinkedIn linking to store refresh token for OAuth login.
     *
     * @param request request body containing actorId and refreshToken (Cognito user refresh token)
     * @return success response
     */
    @POST
    @Path("/linkedin/link/complete")
    @Operation(summary = "Complete LinkedIn account linking")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response completeLinking(final Map<String, String> request)
    {
        return authServiceClient.completeLinkedInLinking(request);
    }
}
