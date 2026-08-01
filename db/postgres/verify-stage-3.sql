DO $$
DECLARE
  paint_status TEXT;
  paint_via TEXT;
  active_stage TEXT;
  blocked_count INT;
  vendor_reply_rate INT;
BEGIN
  SELECT ts.status, ts.completed_via
  INTO paint_status, paint_via
  FROM turn_stage ts
  JOIN "turn" t ON t.id = ts.turn_id
  WHERE t.unit_label = '12B'
    AND t.property_address = '418 Maple St'
    AND t.is_fixture = TRUE
    AND ts.stage_code = 'PAINT';

  IF paint_status <> 'complete' OR paint_via <> 'manual' THEN
    RAISE EXCEPTION 'Expected 12B Paint complete via manual, found status=% via=%', paint_status, paint_via;
  END IF;

  SELECT ts.stage_code
  INTO active_stage
  FROM turn_stage ts
  JOIN "turn" t ON t.id = ts.turn_id
  WHERE t.unit_label = '12B'
    AND t.property_address = '418 Maple St'
    AND t.is_fixture = TRUE
    AND ts.status = 'active';

  IF active_stage <> 'FLOORING' THEN
    RAISE EXCEPTION 'Expected 12B next active stage FLOORING, found %', active_stage;
  END IF;

  SELECT count(*)
  INTO blocked_count
  FROM event_log e
  JOIN turn_stage ts ON ts.id = e.stage_id
  JOIN "turn" t ON t.id = ts.turn_id
  WHERE t.unit_label = '14A'
    AND t.property_address = '418 Maple St'
    AND t.is_fixture = TRUE
    AND ts.stage_code = 'DEEP_CLEAN'
    AND e.event_type = 'guard_blocked'
    AND e.channel = 'board'
    AND e.raw_text ILIKE '%Repairs still open%';

  IF blocked_count < 1 THEN
    RAISE EXCEPTION 'Expected a guard_blocked event for 14A Deep Clean with repairs reason.';
  END IF;

  SELECT COALESCE(round(100.0 * count(*) FILTER (WHERE completed_via = 'vendor_reply') / nullif(count(*), 0))::int, 0)
  INTO vendor_reply_rate
  FROM turn_stage
  WHERE vendor_id IS NOT NULL
    AND status IN ('complete', 'skipped')
    AND completed_at > now() - interval '30 days';

  IF vendor_reply_rate > 67 THEN
    RAISE EXCEPTION 'Expected vendor_reply_rate to drop after manual completion, found %', vendor_reply_rate;
  END IF;
END $$;
