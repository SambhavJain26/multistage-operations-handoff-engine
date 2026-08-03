BEGIN;
SET LOCAL client_min_messages = warning;

DO $$
BEGIN
  IF to_regclass('public.media_asset') IS NULL THEN
    RAISE EXCEPTION 'media_asset table is missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'event_log_event_type_check'
      AND pg_get_constraintdef(oid) LIKE '%stall_alert_held%'
      AND pg_get_constraintdef(oid) LIKE '%chase_drafted%'
      AND pg_get_constraintdef(oid) LIKE '%photo_stored%'
      AND pg_get_constraintdef(oid) LIKE '%unsupported_media%'
  ) THEN
    RAISE EXCEPTION 'Stage 6 event types are not allowed by event_log_event_type_check';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND indexname = 'idx_media_asset_status'
  ) THEN
    RAISE EXCEPTION 'idx_media_asset_status is missing';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM turn_stage
    WHERE status = 'awaiting_approval'
      AND alerted_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'awaiting_approval stages must not be marked as vendor-stall alerted';
  END IF;
END $$;

COMMIT;
