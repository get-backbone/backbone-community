package io.backbone.application.backend.rest;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.*;

import io.backbone.core.client.api.auth.AuthServiceClient;
import io.backbone.core.domain.dto.auth.ForgotPasswordRequest;
import io.backbone.core.domain.dto.auth.ResetPasswordRequest;
import jakarta.ws.rs.core.Response;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

final class AuthControllerTest
{
    private final AuthServiceClient authServiceClient = mock(AuthServiceClient.class);

    private AuthController authController;

    @BeforeEach
    void setUp()
    {
        authController = new AuthController(authServiceClient);
    }

    @Test
    void forgotPasswordProxiesToAuthService()
    {
        final ForgotPasswordRequest request = new ForgotPasswordRequest();
        request.setEmailAddress("user@example.com");
        final Response expected = Response.noContent().build();
        when(authServiceClient.forgotPassword(request)).thenReturn(expected);

        final Response actual = authController.forgotPassword(request);

        assertEquals(expected, actual);
        verify(authServiceClient).forgotPassword(request);
    }

    @Test
    void resetPasswordProxiesToAuthService()
    {
        final ResetPasswordRequest request = new ResetPasswordRequest();
        request.setToken("reset-token");
        request.setNewPassword("NewSecure1!");
        final Response expected = Response.noContent().build();
        when(authServiceClient.resetPassword(request)).thenReturn(expected);

        final Response actual = authController.resetPassword(request);

        assertEquals(expected, actual);
        verify(authServiceClient).resetPassword(request);
    }
}
