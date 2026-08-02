DO $$
DECLARE
  bad_active INT;
  bad_queue INT;
  completion_events INT;
  sent_events INT;
BEGIN
  SELECT count(*)
  INTO bad_active
  FROM (
    SELECT turn_id
    FROM turn_stage
    WHERE status IN ('active', 'awaiting_approval')
    GROUP BY turn_id
    HAVING count(*) > 1
  ) dup;

  IF bad_active > 0 THEN
    RAISE EXCEPTION 'Expected at most one active/awaiting stage per turn, found % violations.', bad_active;
  END IF;

  SELECT count(*)
  INTO bad_queue
  FROM outbound_queue oq
  LEFT JOIN turn_stage ts ON ts.id = oq.stage_id
  WHERE oq.status = 'awaiting_approval'
    AND ts.status <> 'awaiting_approval';

  IF bad_queue > 0 THEN
    RAISE EXCEPTION 'Awaiting outbound queue rows must point at awaiting_approval stages.';
  END IF;

  SELECT count(*)
  INTO completion_events
  FROM event_log
  WHERE event_type = 'stage_complete'
    AND actor_type = 'vendor'
    AND parsed_json->>'stage_state_mutated' = 'true';

  IF completion_events < 1 THEN
    RAISE EXCEPTION 'Expected at least one vendor stage_complete mutation event.';
  END IF;

  SELECT count(*)
  INTO sent_events
  FROM event_log
  WHERE event_type = 'msg_sent'
    AND actor_type = 'manager';

  IF sent_events < 1 THEN
    RAISE EXCEPTION 'Expected at least one manager msg_sent event after Stage 5 Send.';
  END IF;
END $$;
