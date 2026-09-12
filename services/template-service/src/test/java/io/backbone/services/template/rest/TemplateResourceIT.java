package io.backbone.services.template.rest;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import io.backbone.core.test.common.QuarkusLoggingTestResource;
import io.backbone.core.test.common.QuarkusPortsEnvTestResource;
import io.backbone.kit.throttle.impl.test.ThrottlingDisabledTestProfile;
import io.backbone.services.template.domain.dto.TemplateEventRequest;
import io.backbone.services.template.infrastructure.persistence.TemplateEventRecord;
import io.quarkus.test.common.QuarkusTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.TestProfile;
import io.restassured.RestAssured;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import jakarta.transaction.Transactional;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

/**
 * REST API integration test for template event ingest with RDS persistence.
 */
@QuarkusTest
@QuarkusTestResource(QuarkusPortsEnvTestResource.class)
@QuarkusTestResource(QuarkusLoggingTestResource.class)
@TestProfile(ThrottlingDisabledTestProfile.class)
class TemplateResourceIT
{
    @Inject
    EntityManager entityManager;

    @AfterEach
    @Transactional
    void tearDown()
    {
        entityManager.createQuery("DELETE FROM TemplateEventRecord").executeUpdate();
        entityManager.flush();
    }

    @Test
    @Transactional
    void ingestEventSuccess()
    {
        final UUID eventId = UUID.randomUUID();
        final TemplateEventRequest request = TemplateEventRequest.builder()
            .eventId(eventId)
            .message("example event")
            .build();

        RestAssured.given()
            .contentType("application/json")
            .body(request)
            .when()
            .post("/template/events")
            .then()
            .statusCode(201);

        final TemplateEventRecord savedRecord = entityManager.find(TemplateEventRecord.class, eventId);
        assertNotNull(savedRecord, "Template event record should be persisted");
        assertEquals("example event", savedRecord.getMessage());
        assertNotNull(savedRecord.getCreatedAt());
    }

    @Test
    void ingestEventMissingRequiredFieldReturnsBadRequest()
    {
        final TemplateEventRequest request = TemplateEventRequest.builder()
            .eventId(UUID.randomUUID())
            .message("example event")
            .build();
        request.setMessage(null);

        RestAssured.given()
            .contentType("application/json")
            .body(request)
            .when()
            .post("/template/events")
            .then()
            .statusCode(400);
    }

    @Test
    void ingestEventEmptyBodyReturnsBadRequest()
    {
        RestAssured.given()
            .contentType("application/json")
            .body("{}")
            .when()
            .post("/template/events")
            .then()
            .statusCode(400);
    }
}
