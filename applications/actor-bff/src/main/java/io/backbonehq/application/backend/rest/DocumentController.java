package io.backbonehq.application.backend.rest;

import io.backbonehq.core.client.api.document.DocumentServiceClient;
import io.backbonehq.core.common.api.io.FileTransferUtils;
import io.backbonehq.kit.security.api.rest.Secured;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.WebApplicationException;
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
    @Operation(summary = "Get documents")
    public Response getDocuments(@QueryParam("actorId") final String actorId)
    {
        requireNonBlank(actorId, "actorId is required");

        return documentServiceClient.getDocuments(actorId);
    }

    @POST
    @Secured
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Upload and parse documents")
    public Response uploadAndParse(@RestForm("actorId") final String actorId, @RestForm("documents") final List<FileUpload> documents)
    {
        validateUploadRequest(actorId, documents);

        final List<Object> results = documents.stream()
            .map(document -> processDocument(actorId, document))
            .toList();

        return Response.status(Response.Status.CREATED)
            .entity(results)
            .build();
    }

    @POST
    @Path("/{documentId}/link")
    @Secured
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Create a short-lived download link for a document")
    public Response createDocumentLink(@PathParam("documentId") final String documentId, @QueryParam("actorId") final String actorId)
    {
        requireNonBlank(actorId, "actorId is required");
        requireNonBlank(documentId, "documentId is required");

        return documentServiceClient.createDocumentLink(documentId, actorId);
    }

    @DELETE
    @Path("/{documentId}")
    @Secured
    @Operation(summary = "Delete a document and its source object")
    public Response deleteDocument(@PathParam("documentId") final String documentId, @QueryParam("actorId") final String actorId)
    {
        requireNonBlank(actorId, "actorId is required");
        requireNonBlank(documentId, "documentId is required");

        return documentServiceClient.deleteDocument(documentId, actorId);
    }

    private static void validateUploadRequest(final String actorId, final List<FileUpload> documents)
    {
        requireNonBlank(actorId, "actorId is required");

        if (CollectionUtils.isEmpty(documents))
        {
            throw badRequest("No document files provided. Please select at least one file.");
        }
    }

    private static void requireNonBlank(final String value, final String message)
    {
        if (StringUtils.isBlank(value))
        {
            throw badRequest(message);
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
        java.nio.file.Path namedUpload = null;
        try
        {
            // Rest client uses File#getName() as the multipart filename; Quarkus temp paths are not the original name.
            namedUpload = FileTransferUtils.copyToTempDir(document.filePath(), document.fileName());
            try (final Response parseResponse = documentServiceClient.createDocument(actorId, namedUpload.toFile()))
            {
                if (isSuccess(parseResponse))
                {
                    return parseResponse.readEntity(Object.class);
                }

                return errorResult(document, parseResponse);
            }
        }
        catch (final Exception e)
        {
            LOGGER.errorf(e, "Error parsing document: %s", document.fileName());
            return Map.of(
                "fileName", StringUtils.isBlank(document.fileName()) ? "(blank)" : document.fileName(), "error", "Error processing file: " + e
                    .getMessage()
            );
        }
        finally
        {
            FileTransferUtils.deleteQuietly(namedUpload);
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
            "fileName", FileTransferUtils.requireFileName(document.fileName()), "error", StringUtils
                .defaultIfBlank(errorMessage, "Failed to create document"), "status", response.getStatus()
        );
    }
}
