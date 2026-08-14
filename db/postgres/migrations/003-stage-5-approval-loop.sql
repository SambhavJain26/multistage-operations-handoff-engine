BEGIN;
SET LOCAL client_min_messages = warning;

ALTER TABLE turn_stage DROP CONSTRAINT IF EXISTS turn_stage_status_check;
ALTER TABLE turn_stage
  ADD CONSTRAINT turn_stage_status_check
  CHECK (status IN ('pending', 'active', 'awaiting_approval', 'awaiting_delivery', 'complete', 'skipped', 'blocked', 'cancelled'));

ALTER TABLE outbound_queue DROP CONSTRAINT IF EXISTS outbound_queue_status_check;
ALTER TABLE outbound_queue
  ADD CONSTRAINT outbound_queue_status_check
  CHECK (status IN ('awaiting_approval', 'editing', 'approved', 'sending', 'sent', 'partially_sent', 'failed', 'held', 'rejected', 'cancelled', 'configuration_blocked'));

ALTER TABLE outbound_queue
  ADD COLUMN IF NOT EXISTS source_stage_id INT REFERENCES turn_stage(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS approved_text TEXT,
  ADD COLUMN IF NOT EXISTS deterministic_text TEXT,
  ADD COLUMN IF NOT EXISTS draft_model TEXT,
  ADD COLUMN IF NOT EXISTS draft_fallback_used BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS decision_by TEXT,
  ADD COLUMN IF NOT EXISTS edit_prompted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS sent_to_sender_ref TEXT,
  ADD COLUMN IF NOT EXISTS manager_message_id TEXT,
  ADD COLUMN IF NOT EXISTS approval_context JSONB NOT NULL DEFAULT '{}'::jsonb;

UPDATE outbound_queue
SET approved_text = draft_text
WHERE approved_text IS NULL;

ALTER TABLE event_log DROP CONSTRAINT IF EXISTS event_log_channel_check;
ALTER TABLE event_log
  ADD CONSTRAINT event_log_channel_check
  CHECK (channel IN ('telegram', 'email', 'airtable', 'generic', 'board', 'digest', 'seed', 'import', 'form', 'system'));

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
      'turn_cancelled',
      'workflow_error',
      'email_auto_ignored', 'delivery_approved', 'delivery_sent', 'delivery_failed',
      'delivery_retry', 'airtable_sync', 'airtable_sync_failed'
    )
  );

CREATE INDEX IF NOT EXISTS idx_stage_approval ON turn_stage(status, activated_at)
  WHERE status = 'awaiting_approval';
CREATE INDEX IF NOT EXISTS idx_outbound_status ON outbound_queue(status, created_at);
CREATE INDEX IF NOT EXISTS idx_outbound_source_stage ON outbound_queue(source_stage_id);

COMMIT;
