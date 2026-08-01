DO $$
DECLARE
  missing_count integer;
BEGIN
  SELECT count(*)
  INTO missing_count
  FROM (VALUES
    ('turn_intake'),
    ('vendor_inbound'),
    ('manager_match_needed'),
    ('duplicate_inbound')
  ) required(event_type)
  WHERE NOT EXISTS (
    SELECT 1
    FROM pg_constraint c
    WHERE c.conname = 'event_log_event_type_check'
      AND pg_get_constraintdef(c.oid) LIKE '%' || required.event_type || '%'
  );

  IF missing_count <> 0 THEN
    RAISE EXCEPTION 'Stage 4 event_type constraint is missing % expected values.', missing_count;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint c
    WHERE c.conname = 'event_log_channel_check'
      AND pg_get_constraintdef(c.oid) LIKE '%form%'
  ) THEN
    RAISE EXCEPTION 'Stage 4 channel constraint is missing form.';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM event_log
    WHERE event_type IN ('vendor_inbound', 'manager_match_needed', 'duplicate_inbound', 'unknown_sender')
      AND coalesce((parsed_json->>'stage_state_mutated')::boolean, false) = true
  ) THEN
    RAISE EXCEPTION 'Stage 4 vendor inbound event claims stage mutation.';
  END IF;
END $$;
