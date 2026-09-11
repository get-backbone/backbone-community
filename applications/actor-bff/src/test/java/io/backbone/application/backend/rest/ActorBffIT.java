package io.backbone.application.backend.rest;

import io.backbone.core.common.api.test.QuarkusLoggingTestResource;
import io.backbone.core.common.api.test.QuarkusPortsEnvTestResource;
import io.backbone.kit.throttle.impl.test.ThrottlingDisabledTestProfile;
import io.quarkus.test.common.QuarkusTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.TestProfile;
import io.restassured.RestAssured;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Process boots, and {@code @Secured} endpoints enforce auth.
 */
@QuarkusTest
@QuarkusTestResource(QuarkusPortsEnvTestResource.class)
@QuarkusTestResource(QuarkusLoggingTestResource.class)
@TestProfile(ThrottlingDisabledTestProfile.class)
class ActorBffIT
{
    @Test
    @DisplayName("liveness probe succeeds")
    void livenessProbeSucceeds()
    {
        RestAssured.when()
            .get("/q/health/live")
            .then()
            .statusCode(200);
    }

    @Test
    @DisplayName("secured actor endpoint requires authentication")
    void securedActorEndpointRequiresAuthentication()
    {
        RestAssured.when()
            .get("/actors/actor-1")
            .then()
            .statusCode(401);
    }
}
