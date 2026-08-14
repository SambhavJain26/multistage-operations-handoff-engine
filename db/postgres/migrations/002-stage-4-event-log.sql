BEGIN;
SET LOCAL client_min_messages = warning;

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
      'msg_edit_requested',
      'msg_edited',
      'msg_rejected',
      'workflow_error',
      'email_auto_ignored', 'delivery_approved', 'delivery_sent', 'delivery_failed',
      'delivery_retry', 'airtable_sync', 'airtable_sync_failed'
    )
  );

COMMIT;
