DO $$
DECLARE
  missing_tables INT;
  missing_indexes INT;
  fixture_turns INT;
  fixture_vendors INT;
  fixture_stages INT;
  active_stage_violations INT;
  age_12b NUMERIC;
  age_3_oak NUMERIC;
BEGIN
  SELECT count(*) INTO missing_tables
  FROM (VALUES ('vendor'), ('turn'), ('turn_stage'), ('outbound_queue'), ('event_log')) AS expected(table_name)
  LEFT JOIN information_schema.tables t
    ON t.table_schema = 'public' AND t.table_name = expected.table_name
  WHERE t.table_name IS NULL;

  IF missing_tables <> 0 THEN
    RAISE EXCEPTION 'Missing required table count: %', missing_tables;
  END IF;

  SELECT count(*) INTO missing_indexes
  FROM (
    VALUES
      ('idx_stage_active'),
      ('idx_vendor_chat'),
      ('idx_event_metrics'),
      ('idx_turn_fixture_status'),
      ('uniq_one_active_stage_per_turn'),
      ('uniq_outbound_awaiting_per_stage_vendor')
  ) AS expected(index_name)
  LEFT JOIN pg_indexes i
    ON i.schemaname = 'public' AND i.indexname = expected.index_name
  WHERE i.indexname IS NULL;

  IF missing_indexes <> 0 THEN
    RAISE EXCEPTION 'Missing required index count: %', missing_indexes;
  END IF;

  SELECT count(*) INTO fixture_turns FROM "turn" WHERE is_fixture = TRUE;
  SELECT count(*) INTO fixture_vendors FROM vendor WHERE is_fixture = TRUE;
  SELECT count(*) INTO fixture_stages
  FROM turn_stage ts
  JOIN "turn" t ON t.id = ts.turn_id
  WHERE t.is_fixture = TRUE;

  IF fixture_turns <> 6 THEN
    RAISE EXCEPTION 'Expected 6 fixture turns, found %', fixture_turns;
  END IF;

  IF fixture_vendors <> 6 THEN
    RAISE EXCEPTION 'Expected 6 fixture vendors, found %', fixture_vendors;
  END IF;

  IF fixture_stages <> 66 THEN
    RAISE EXCEPTION 'Expected 66 fixture stages, found %', fixture_stages;
  END IF;

  SELECT count(*) INTO active_stage_violations
  FROM (
    SELECT turn_id, count(*) AS active_count
    FROM turn_stage
    WHERE status = 'active'
    GROUP BY turn_id
  ) active_counts
  WHERE active_count <> 1;

  IF active_stage_violations <> 0 THEN
    RAISE EXCEPTION 'Every fixture turn must have exactly one active stage.';
  END IF;

  SELECT extract(epoch FROM (now() - ts.activated_at)) / 3600 INTO age_12b
  FROM turn_stage ts
  JOIN "turn" t ON t.id = ts.turn_id
  WHERE t.unit_label = '12B'
    AND t.property_address = '418 Maple St'
    AND t.is_fixture = TRUE
    AND ts.stage_code = 'PAINT';

  IF age_12b NOT BETWEEN 95 AND 98 THEN
    RAISE EXCEPTION 'Expected 12B Paint age near 96 hours, found %', age_12b;
  END IF;

  SELECT extract(epoch FROM (now() - ts.activated_at)) / 3600 INTO age_3_oak
  FROM turn_stage ts
  JOIN "turn" t ON t.id = ts.turn_id
  WHERE t.unit_label = '3'
    AND t.property_address = '2201 Oak Ave'
    AND t.is_fixture = TRUE
    AND ts.stage_code = 'TRASHOUT';

  IF age_3_oak NOT BETWEEN 29 AND 32 THEN
    RAISE EXCEPTION 'Expected 3 Oak Trash-out age near 30 hours, found %', age_3_oak;
  END IF;
END $$;

WITH current_stage AS (
  SELECT
    t.unit_label,
    t.property_address,
    ts.stage_code,
    ts.stage_name,
    round(extract(epoch FROM (now() - ts.activated_at)) / 3600, 1) AS hours_at_stage,
    greatest((current_date - t.moveout_date), 0) AS vacancy_days,
    round((t.rent_monthly / 30) * greatest((current_date - t.moveout_date), 0), 2) AS dollars_burned
  FROM "turn" t
  JOIN turn_stage ts ON ts.turn_id = t.id AND ts.status = 'active'
  WHERE t.is_fixture = TRUE
)
SELECT *
FROM current_stage
ORDER BY
  CASE
    WHEN stage_code = 'PAINT' THEN 1
    WHEN stage_code = 'TRASHOUT' THEN 2
    ELSE 3
  END,
  hours_at_stage DESC;

SELECT
  round(100.0 * count(*) FILTER (WHERE completed_via = 'vendor_reply') / nullif(count(*), 0)) AS vendor_reply_rate
FROM turn_stage
WHERE vendor_id IS NOT NULL
  AND status IN ('complete', 'skipped')
  AND completed_at > now() - interval '30 days';

SELECT
  round(100.0 * count(*) FILTER (WHERE event_type = 'stage_complete') / nullif(count(*), 0)) AS auto_handled_rate
FROM event_log
WHERE actor_type = 'vendor'
  AND created_at > now() - interval '30 days';
