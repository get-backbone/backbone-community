package io.backbone.application.backend.rest;

import io.backbone.application.backend.infrastructure.ClientWebApplicationExceptionMapper;
import io.backbone.core.client.api.auth.AuthServiceClient;
import io.backbone.core.domain.dto.actor.RegisterRequest;
import io.backbone.core.domain.dto.auth.ForgotPasswordRequest;
import io.backbone.core.domain.dto.auth.LoginRequest;
import io.backbone.core.domain.dto.auth.RefreshRequest;
import io.backbone.core.domain.dto.auth.ResetPasswordRequest;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.Map;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;
import org.eclipse.microprofile.rest.client.inject.RestClient;

/**
 * REST controller for authentication endpoints.
 * Proxies requests to auth-service, providing a single entry point for frontend clients.
 * <p>
 * Outbound {@link org.jboss.resteasy.reactive.ClientWebApplicationException} (e.g. 401) is mapped
 * by {@link ClientWebApplicationExceptionMapper}.
 */
@Path("/auth")
public final class AuthController
{
    private final AuthServiceClient authServiceClient;

    @Inject
    public AuthController(@RestClient final AuthServiceClient authServiceClient)
    {
        this.authServiceClient = authServiceClient;
    }

    @POST
    @Path("/login")
    @Tag(name = "Actor Auth")
    @Operation(summary = "Login")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response login(@Valid final LoginRequest request)
    {
        return authServiceClient.login(request);
    }

    @POST
    @Path("/register")
    @Tag(name = "Actor Auth")
    @Operation(summary = "Register")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response register(@Valid final RegisterRequest request)
    {
        return authServiceClient.register(request);
    }

    @POST
    @Path("/forgot-password")
    @Tag(name = "Actor Auth")
    @Operation(summary = "Forgot password")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response forgotPassword(@Valid final ForgotPasswordRequest request)
    {
        return authServiceClient.forgotPassword(request);
    }

    @POST
    @Path("/reset-password")
    @Tag(name = "Actor Auth")
    @Operation(summary = "Reset password")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response resetPassword(@Valid final ResetPasswordRequest request)
    {
        return authServiceClient.resetPassword(request);
    }

    @POST
    @Path("/tokens/refresh")
    @Tag(name = "Provider Auth")
    @Operation(summary = "Refresh access token")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    // keep the browser session alive: swap a Cognito refresh token for a new access/id token pair
    public Response refreshUserToken(@Valid final RefreshRequest request)
    {
        return authServiceClient.refreshUserToken(request);
    }

    @POST
    @Path("/tokens/exchange")
    @Tag(name = "Provider Auth")
    @Operation(summary = "Exchange token")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    // after Google/LinkedIn OAuth redirect: swap the one-time opaque token for Cognito session tokens
    public Response exchangeToken(final Map<String, String> request)
    {
        return authServiceClient.exchangeToken(request);
    }
}
