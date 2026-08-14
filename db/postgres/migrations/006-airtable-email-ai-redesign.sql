BEGIN;
SET LOCAL client_min_messages = warning;

ALTER TABLE vendor
  ADD COLUMN IF NOT EXISTS email_address TEXT;

ALTER TABLE turn_stage DROP CONSTRAINT IF EXISTS turn_stage_status_check;
ALTER TABLE turn_stage
  ADD CONSTRAINT turn_stage_status_check
  CHECK (status IN ('pending', 'active', 'awaiting_approval', 'awaiting_delivery', 'complete', 'skipped', 'blocked', 'cancelled'));

ALTER TABLE outbound_queue
  ADD COLUMN IF NOT EXISTS reply_token TEXT,
  ADD COLUMN IF NOT EXISTS email_subject TEXT,
  ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ;

UPDATE outbound_queue
SET reply_token = upper(substr(md5(id::text || created_at::text), 1, 8))
WHERE reply_token IS NULL OR reply_token = '';

ALTER TABLE outbound_queue
  ALTER COLUMN reply_token SET DEFAULT upper(substr(md5(random()::text || clock_timestamp()::text), 1, 8)),
  ALTER COLUMN reply_token SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uniq_outbound_reply_token ON outbound_queue(reply_token);

UPDATE outbound_queue SET channel = 'generic' WHERE channel = 'board';

ALTER TABLE outbound_queue DROP CONSTRAINT IF EXISTS outbound_queue_channel_check;
ALTER TABLE outbound_queue
  ADD CONSTRAINT outbound_queue_channel_check
  CHECK (channel IN ('telegram', 'email', 'dual', 'generic', 'digest'));

ALTER TABLE outbound_queue DROP CONSTRAINT IF EXISTS outbound_queue_status_check;
ALTER TABLE outbound_queue
  ADD CONSTRAINT outbound_queue_status_check
  CHECK (status IN (
    'awaiting_approval', 'editing', 'approved', 'sending', 'sent',
    'partially_sent', 'failed', 'held', 'rejected', 'cancelled', 'configuration_blocked'
  ));

CREATE TABLE IF NOT EXISTS communication_message (
  id                    BIGSERIAL PRIMARY KEY,
  direction             TEXT NOT NULL CHECK (direction IN ('inbound', 'outbound')),
  channel               TEXT NOT NULL CHECK (channel IN ('telegram', 'email', 'generic')),
  vendor_id             INT REFERENCES vendor(id) ON DELETE SET NULL,
  turn_id               INT REFERENCES "turn"(id) ON DELETE CASCADE,
  stage_id              INT REFERENCES turn_stage(id) ON DELETE SET NULL,
  outbound_queue_id     INT REFERENCES outbound_queue(id) ON DELETE SET NULL,
  provider_message_id   TEXT,
  thread_ref            TEXT,
  in_reply_to           TEXT,
  sender_ref            TEXT,
  recipient_ref         TEXT,
  subject               TEXT,
  body_text             TEXT,
  normalized_text       TEXT,
  intent                TEXT,
  ai_confidence         NUMERIC(5,4),
  ai_summary            TEXT,
  ai_result             JSONB,
  status                TEXT NOT NULL DEFAULT 'received' CHECK (status IN ('received', 'processed', 'ignored', 'sent', 'failed', 'needs_manager')),
  received_at           TIMESTAMPTZ,
  sent_at               TIMESTAMPTZ,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS uniq_communication_provider_message
  ON communication_message(channel, provider_message_id)
  WHERE provider_message_id IS NOT NULL AND provider_message_id <> '';
CREATE INDEX IF NOT EXISTS idx_communication_thread ON communication_message(thread_ref, created_at);
CREATE INDEX IF NOT EXISTS idx_communication_vendor ON communication_message(vendor_id, created_at);
CREATE INDEX IF NOT EXISTS idx_communication_turn ON communication_message(turn_id, created_at);

CREATE TABLE IF NOT EXISTS outbound_delivery (
  id                  BIGSERIAL PRIMARY KEY,
  outbound_queue_id   INT NOT NULL REFERENCES outbound_queue(id) ON DELETE CASCADE,
  channel             TEXT NOT NULL CHECK (channel IN ('telegram', 'email')),
  destination         TEXT NOT NULL,
  subject             TEXT,
  body_text           TEXT NOT NULL,
  status              TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sending', 'sent', 'failed', 'retry_pending', 'cancelled')),
  attempt_count       INT NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  provider_message_id TEXT,
  last_error          TEXT,
  last_attempt_at     TIMESTAMPTZ,
  sent_at             TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (outbound_queue_id, channel)
);

CREATE INDEX IF NOT EXISTS idx_outbound_delivery_status ON outbound_delivery(status, created_at);

CREATE TABLE IF NOT EXISTS airtable_record_map (
  id                 BIGSERIAL PRIMARY KEY,
  entity_type        TEXT NOT NULL CHECK (entity_type IN ('vendor', 'turn', 'stage', 'communication', 'approval', 'intake')),
  entity_id          BIGINT NOT NULL,
  airtable_table     TEXT NOT NULL,
  airtable_record_id TEXT NOT NULL,
  payload_hash       TEXT,
  last_synced_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_error         TEXT,
  UNIQUE (entity_type, entity_id),
  UNIQUE (airtable_table, airtable_record_id)
);

CREATE INDEX IF NOT EXISTS idx_airtable_record_map_sync ON airtable_record_map(entity_type, last_synced_at);

UPDATE event_log SET channel = 'generic' WHERE channel = 'board';

ALTER TABLE event_log DROP CONSTRAINT IF EXISTS event_log_channel_check;
ALTER TABLE event_log
  ADD CONSTRAINT event_log_channel_check
  CHECK (channel IN ('telegram', 'email', 'airtable', 'generic', 'digest', 'seed', 'import', 'form', 'system'));

ALTER TABLE event_log DROP CONSTRAINT IF EXISTS event_log_event_type_check;
ALTER TABLE event_log
  ADD CONSTRAINT event_log_event_type_check
  CHECK (event_type IN (
    'reply_received', 'stage_complete', 'guard_blocked', 'override', 'msg_drafted', 'msg_sent',
    'msg_held', 'msg_edit_requested', 'msg_edited', 'msg_rejected', 'stall_alert', 'stall_alert_held',
    'chase_drafted', 'weekly_digest', 'health_check', 'photo_received', 'photo_stored',
    'manager_photo_match_needed', 'unsupported_media', 'unmatched', 'unknown_sender', 'manual_advance',
    'stage_seeded', 'prospect_imported', 'turn_intake', 'vendor_inbound', 'manager_match_needed',
    'duplicate_inbound', 'classification_fallback', 'draft_fallback', 'stage_awaiting_approval',
    'stage_skipped', 'stage_snoozed', 'turn_cancelled', 'workflow_error', 'email_auto_ignored',
    'delivery_approved', 'delivery_sent', 'delivery_failed', 'delivery_retry', 'airtable_sync',
    'airtable_sync_failed'
  ));

ALTER TABLE media_asset DROP CONSTRAINT IF EXISTS media_asset_channel_check;
ALTER TABLE media_asset
  ADD CONSTRAINT media_asset_channel_check
  CHECK (channel IN ('telegram', 'email', 'generic'));

CREATE INDEX IF NOT EXISTS idx_vendor_email ON vendor(lower(email_address)) WHERE email_address IS NOT NULL;

COMMIT;
