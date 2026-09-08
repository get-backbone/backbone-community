package io.backbone.application.backend.rest;

import io.backbone.core.client.api.document.DocumentServiceClient;
import io.backbone.kit.security.api.rest.Secured;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.List;
import java.util.Map;
import org.apache.commons.collections4.CollectionUtils;
import org.apache.commons.lang3.StringUtils;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;
import org.eclipse.microprofile.rest.client.inject.RestClient;
import org.jboss.logging.Logger;
import org.jboss.resteasy.reactive.RestForm;
import org.jboss.resteasy.reactive.multipart.FileUpload;

@Path("/documents")
@Tag(name = "Documents")
public final class DocumentController
{
    private static final Logger LOGGER = Logger.getLogger(DocumentController.class);

    private final DocumentServiceClient documentServiceClient;

    @Inject
    public DocumentController(@RestClient final DocumentServiceClient documentServiceClient)
    {
        this.documentServiceClient = documentServiceClient;
    }

    @GET
    @Secured
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "List documents for an actor")
    public Response getDocuments(@QueryParam("actorId") final String actorId)
    {
        requireActorId(actorId);
        return documentServiceClient.getDocuments(actorId);
    }

    @POST
    @Secured
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Upload and parse documents for an actor")
    public Response upload(@RestForm("actorId") final String actorId, @RestForm("documents") final List<FileUpload> documents)
    {
        validateUploadRequest(actorId, documents);

        final List<Object> results = documents.stream()
            .map(document -> processDocument(actorId, document))
            .toList();

        return Response.status(Response.Status.CREATED)
            .entity(results)
            .build();
    }

    private static void validateUploadRequest(final String actorId, final List<FileUpload> documents)
    {
        requireActorId(actorId);

        if (CollectionUtils.isEmpty(documents))
        {
            throw badRequest("No document files provided. Please select at least one file.");
        }
    }

    private static void requireActorId(final String actorId)
    {
        if (StringUtils.isEmpty(actorId))
        {
            throw badRequest("actorId is required");
        }
    }

    private static WebApplicationException badRequest(final String message)
    {
        return new WebApplicationException(
            Response.status(Response.Status.BAD_REQUEST)
                .entity(Map.of("error", message))
                .build()
        );
    }

    private Object processDocument(final String actorId, final FileUpload document)
    {
        try (Response parseResponse = documentServiceClient.createDocument(actorId, document.filePath().toFile()))
        {
            if (isSuccess(parseResponse))
            {
                return parseResponse.readEntity(Object.class);
            }

            return errorResult(document, parseResponse);
        }
        catch (final Exception e)
        {
            LOGGER.errorf(e, "Error parsing document: %s", document.fileName());
            return Map.of(
                "fileName", safeFileName(document), "error", "Error processing file: " + e.getMessage()
            );
        }
    }

    private static boolean isSuccess(final Response response)
    {
        final int status = response.getStatus();
        return status == Response.Status.CREATED.getStatusCode() || status == Response.Status.OK.getStatusCode();
    }

    private static Map<String, Object> errorResult(final FileUpload document, final Response response)
    {
        final String errorMessage = response.readEntity(String.class);

        return Map.of(
            "fileName", safeFileName(document), "error", StringUtils.defaultIfBlank(errorMessage, "Failed to create document"), "status", response
                .getStatus()
        );
    }

    private static String safeFileName(final FileUpload document)
    {
        return StringUtils.defaultIfBlank(document.fileName(), "unknown");
    }
}
