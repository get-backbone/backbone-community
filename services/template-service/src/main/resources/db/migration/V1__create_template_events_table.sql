CREATE SCHEMA IF NOT EXISTS template;

CREATE TABLE template.template_events (
    event_id UUID PRIMARY KEY,
    message TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_template_events_created_at ON template.template_events(created_at);
