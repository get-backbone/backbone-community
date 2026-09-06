package io.backbone.application.backend.rest;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.*;

import io.backbone.core.client.document.DocumentServiceClient;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Response;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

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
}
