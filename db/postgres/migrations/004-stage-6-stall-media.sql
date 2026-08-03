BEGIN;
SET LOCAL client_min_messages = warning;

ALTER TABLE event_log DROP CONSTRAINT IF EXISTS event_log_event_type_check;
ALTER TABLE event_log
  ADD CONSTRAINT event_log_event_type_check
  CHECK (
    event_type IN (
      'reply_received',
      'stage_complete',
      'guard_blocked',
      'override',
      'msg_drafted',
      'msg_sent',
      'msg_held',
      'msg_edit_requested',
      'msg_edited',
      'msg_rejected',
      'stall_alert',
      'stall_alert_held',
      'chase_drafted',
      'weekly_digest',
      'health_check',
      'photo_received',
      'photo_stored',
      'manager_photo_match_needed',
      'unsupported_media',
      'unmatched',
      'unknown_sender',
      'manual_advance',
      'stage_seeded',
      'prospect_imported',
      'turn_intake',
      'vendor_inbound',
      'manager_match_needed',
      'duplicate_inbound',
      'classification_fallback',
      'draft_fallback',
      'stage_awaiting_approval',
      'stage_skipped',
      'stage_snoozed',
      'turn_cancelled'
    )
  );

CREATE TABLE IF NOT EXISTS media_asset (
  id          SERIAL PRIMARY KEY,
  turn_id     INT REFERENCES "turn"(id) ON DELETE CASCADE,
  stage_id    INT REFERENCES turn_stage(id) ON DELETE SET NULL,
  vendor_id   INT REFERENCES vendor(id) ON DELETE SET NULL,
  channel     TEXT NOT NULL CHECK (channel IN ('telegram', 'generic')),
  sender_ref  TEXT,
  media_type  TEXT NOT NULL CHECK (media_type IN ('photo', 'voice', 'unsupported')),
  file_id     TEXT,
  local_path  TEXT,
  caption     TEXT,
  status      TEXT NOT NULL DEFAULT 'received' CHECK (status IN ('received', 'stored', 'needs_manager', 'unsupported')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_media_asset_stage ON media_asset(stage_id, created_at);
CREATE INDEX IF NOT EXISTS idx_media_asset_status ON media_asset(status, created_at);

COMMIT;
