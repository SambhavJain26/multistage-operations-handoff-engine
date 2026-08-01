BEGIN;
SET LOCAL client_min_messages = warning;

ALTER TABLE event_log DROP CONSTRAINT IF EXISTS event_log_channel_check;
ALTER TABLE event_log
  ADD CONSTRAINT event_log_channel_check
  CHECK (channel IN ('telegram', 'generic', 'board', 'digest', 'seed', 'import', 'form'));

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
      'unmatched',
      'unknown_sender',
      'manual_advance',
      'stage_seeded',
      'prospect_imported',
      'turn_intake',
      'vendor_inbound',
      'manager_match_needed',
      'duplicate_inbound'
    )
  );

COMMIT;
