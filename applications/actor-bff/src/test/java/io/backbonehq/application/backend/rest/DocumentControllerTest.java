package io.backbonehq.application.backend.rest;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

import io.backbonehq.core.client.api.document.DocumentServiceClient;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Response;
import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;
import org.jboss.resteasy.reactive.multipart.FileUpload;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.mockito.ArgumentCaptor;

final class DocumentControllerTest
{
    private DocumentController documentController;
    private DocumentServiceClient documentServiceClient;

    @BeforeEach
    void setUp()
    {
        documentServiceClient = mock(DocumentServiceClient.class);
        documentController = new DocumentController(documentServiceClient);
    }

    @Test
    void getDocumentsRequiresActorId()
    {
        final WebApplicationException exception = assertThrows(
            WebApplicationException.class, () -> documentController.getDocuments(null)
        );

        assertEquals(Response.Status.BAD_REQUEST.getStatusCode(), exception.getResponse().getStatus());
    }

    @Test
    void getDocumentsProxiesToDocumentService()
    {
        final Response expected = Response.ok().build();
        when(documentServiceClient.getDocuments("actor-1")).thenReturn(expected);

        final Response actual = documentController.getDocuments("actor-1");

        assertEquals(expected, actual);
        verify(documentServiceClient).getDocuments("actor-1");
    }

    @Test
    void createDocumentLinkRequiresActorId()
    {
        final WebApplicationException exception = assertThrows(
            WebApplicationException.class, () -> documentController.createDocumentLink("doc-1", null)
        );

        assertEquals(Response.Status.BAD_REQUEST.getStatusCode(), exception.getResponse().getStatus());
    }

    @Test
    void createDocumentLinkProxiesToDocumentService()
    {
        final Response expected = Response.ok().build();
        when(documentServiceClient.createDocumentLink("doc-1", "actor-1")).thenReturn(expected);

        final Response actual = documentController.createDocumentLink("doc-1", "actor-1");

        assertEquals(expected, actual);
        verify(documentServiceClient).createDocumentLink("doc-1", "actor-1");
    }

    @Test
    void deleteDocumentRequiresActorId()
    {
        final WebApplicationException exception = assertThrows(
            WebApplicationException.class, () -> documentController.deleteDocument("doc-1", null)
        );

        assertEquals(Response.Status.BAD_REQUEST.getStatusCode(), exception.getResponse().getStatus());
    }

    @Test
    void deleteDocumentProxiesToDocumentService()
    {
        final Response expected = Response.noContent().build();
        when(documentServiceClient.deleteDocument("doc-1", "actor-1")).thenReturn(expected);

        final Response actual = documentController.deleteDocument("doc-1", "actor-1");

        assertEquals(expected, actual);
        verify(documentServiceClient).deleteDocument("doc-1", "actor-1");
    }

    @Test
    void uploadAndParseForwardsOriginalFileName(@TempDir final Path tempDir) throws Exception
    {
        final Path quarkusTemp = tempDir.resolve("resteasy-reactive5779703987260341527upload");
        Files.writeString(quarkusTemp, "pdf-bytes");

        final FileUpload upload = mock(FileUpload.class);
        when(upload.fileName()).thenReturn("dummy-resume.pdf");
        when(upload.filePath()).thenReturn(quarkusTemp);

        when(documentServiceClient.createDocument(eq("actor-1"), any(File.class)))
            .thenReturn(Response.status(Response.Status.CREATED).entity(Map.of("ok", true)).build());

        final Response response = documentController.uploadAndParse("actor-1", List.of(upload));

        assertEquals(Response.Status.CREATED.getStatusCode(), response.getStatus());

        final ArgumentCaptor<File> fileCaptor = ArgumentCaptor.forClass(File.class);
        verify(documentServiceClient).createDocument(eq("actor-1"), fileCaptor.capture());
        assertEquals("dummy-resume.pdf", fileCaptor.getValue().getName());
    }
}
