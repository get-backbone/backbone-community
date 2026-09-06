package io.backbone.services.template.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import lombok.Data;

/**
 * JPA record for persisted template example events.
 */
@Data
@Entity
@Table(name = "template_events", schema = "template")
public class TemplateEventRecord
{
    @Id
    @Column(name = "event_id", nullable = false)
    private UUID eventId;

    @Column(name = "message", nullable = false, columnDefinition = "TEXT")
    private String message;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
}
