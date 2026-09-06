package io.backbone.application.backend.infrastructure;

import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;
import org.jboss.resteasy.reactive.ClientWebApplicationException;

/**
 * Maps REST client failures from the BFF's outbound calls into HTTP responses for the browser.
 * <p>
 * Without this, {@link ClientWebApplicationException} (e.g. upstream 401) is treated as an
 * unhandled server error and surfaces as HTTP 500.
 * <p>
 * For upstream 4xx, forwards status and JSON body. For other cases, delegates via
 * {@link WebApplicationException} so the runtime can apply normal handling (do not rethrow
 * {@link ClientWebApplicationException} here or the mapper may be invoked again).
 */
@Provider
public final class ClientWebApplicationExceptionMapper implements ExceptionMapper<ClientWebApplicationException>
{
    @Override
    public Response toResponse(final ClientWebApplicationException exception)
    {
        final Response upstream = exception.getResponse();
        if (upstream == null)
        {
            throw new WebApplicationException(exception);
        }
        final int status = upstream.getStatus();
        if (status >= 400 && status < 500)
        {
            return forwardClientError(upstream);
        }
        throw new WebApplicationException(upstream);
    }

    private static Response forwardClientError(final Response upstream)
    {
        final Response.ResponseBuilder builder = Response.status(upstream.getStatus());
        upstream.getHeaders().forEach(builder::header);

        builder.type(upstream.getMediaType() != null ? upstream.getMediaType() : MediaType.APPLICATION_JSON_TYPE);

        if (upstream.hasEntity())
        {
            builder.entity(upstream.readEntity(String.class));
        }

        return builder.build();
    }
}
