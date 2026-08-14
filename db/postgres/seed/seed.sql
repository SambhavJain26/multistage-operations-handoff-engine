BEGIN;
SET LOCAL client_min_messages = warning;

WITH fixture_turns AS (
  SELECT id FROM "turn" WHERE is_fixture = TRUE
),
fixture_stages AS (
  SELECT id FROM turn_stage WHERE turn_id IN (SELECT id FROM fixture_turns)
)
DELETE FROM event_log
WHERE turn_id IN (SELECT id FROM fixture_turns)
   OR stage_id IN (SELECT id FROM fixture_stages);

DELETE FROM event_log
WHERE actor_type = 'vendor'
  AND channel IN ('generic', 'telegram', 'email')
  AND event_type IN ('vendor_inbound', 'manager_match_needed', 'duplicate_inbound', 'unknown_sender')
  AND (
    actor_id LIKE 'placeholder\_%' ESCAPE '\'
    OR actor_id = 'mystery_vendor'
  );

DELETE FROM airtable_record_map
WHERE (entity_type = 'approval' AND entity_id IN (
    SELECT id FROM outbound_queue
    WHERE turn_id IN (SELECT id FROM "turn" WHERE is_fixture = TRUE)
       OR vendor_id IN (SELECT id FROM vendor WHERE is_fixture = TRUE)
  ))
   OR (entity_type = 'communication' AND entity_id IN (
    SELECT id FROM communication_message
    WHERE turn_id IN (SELECT id FROM "turn" WHERE is_fixture = TRUE)
       OR vendor_id IN (SELECT id FROM vendor WHERE is_fixture = TRUE)
  ))
   OR (entity_type = 'intake' AND entity_id IN (SELECT id FROM "turn" WHERE is_fixture = TRUE));

DELETE FROM outbound_queue
WHERE turn_id IN (SELECT id FROM "turn" WHERE is_fixture = TRUE)
   OR vendor_id IN (SELECT id FROM vendor WHERE is_fixture = TRUE)
   OR stage_id IN (
      SELECT ts.id
      FROM turn_stage ts
      JOIN "turn" t ON t.id = ts.turn_id
      WHERE t.is_fixture = TRUE
   );

DELETE FROM media_asset
WHERE turn_id IN (SELECT id FROM "turn" WHERE is_fixture = TRUE)
   OR stage_id IN (
      SELECT ts.id
      FROM turn_stage ts
      JOIN "turn" t ON t.id = ts.turn_id
      WHERE t.is_fixture = TRUE
   )
   OR sender_ref LIKE 'placeholder\_%' ESCAPE '\'
   OR sender_ref = 'mystery_vendor';

DELETE FROM communication_message
WHERE turn_id IN (SELECT id FROM "turn" WHERE is_fixture = TRUE)
   OR vendor_id IN (SELECT id FROM vendor WHERE is_fixture = TRUE)
   OR sender_ref LIKE 'placeholder\_%' ESCAPE '\'
   OR sender_ref = 'mystery_vendor';

DELETE FROM airtable_record_map
WHERE (entity_type = 'turn' AND entity_id IN (SELECT id FROM "turn" WHERE is_fixture = TRUE))
   OR (entity_type = 'stage' AND entity_id IN (
      SELECT ts.id FROM turn_stage ts JOIN "turn" t ON t.id = ts.turn_id WHERE t.is_fixture = TRUE
   ))
   OR (entity_type = 'vendor' AND entity_id IN (SELECT id FROM vendor WHERE is_fixture = TRUE));

DELETE FROM "turn" WHERE is_fixture = TRUE;
DELETE FROM vendor WHERE is_fixture = TRUE;

INSERT INTO vendor (name, trade, telegram_chat_id, phone_e164, email_address, active, is_fixture) VALUES
  ('Rivera Painting', 'paint', 'placeholder_rivera_painting_tg', 'placeholder_rivera_painting', 'rivera@example.com', TRUE, TRUE),
  ('Maria''s Cleaning Co', 'clean', 'placeholder_marias_cleaning_tg', 'placeholder_marias_cleaning', 'marias@example.com', TRUE, TRUE),
  ('Dale Hutchins', 'repairs', 'placeholder_dale_hutchins_tg', 'placeholder_dale_hutchins', 'dale@example.com', TRUE, TRUE),
  ('QuickHaul Junk Removal', 'trashout', 'placeholder_quickhaul_junk_tg', 'placeholder_quickhaul_junk', 'quickhaul@example.com', TRUE, TRUE),
  ('Statewide Flooring', 'flooring', 'placeholder_statewide_flooring_tg', 'placeholder_statewide_flooring', 'statewide@example.com', TRUE, TRUE),
  ('Cedar Ridge in-house', 'inspect', 'placeholder_cedar_inhouse_tg', 'placeholder_cedar_inhouse', 'inhouse@example.com', TRUE, TRUE);

CREATE TEMP TABLE stage_template_seed (
  seq INT PRIMARY KEY,
  stage_code TEXT NOT NULL,
  stage_name TEXT NOT NULL,
  sla_hours INT NOT NULL
) ON COMMIT DROP;

INSERT INTO stage_template_seed (seq, stage_code, stage_name, sla_hours) VALUES
  (0, 'NOTICE', 'Notice received', 0),
  (1, 'PRE_INSPECT', 'Pre-move-out inspection', 48),
  (2, 'MOVEOUT', 'Move-out / keys returned', 0),
  (3, 'INSPECT_PUNCH', 'Inspection + punch list', 24),
  (4, 'TRASHOUT', 'Trash-out', 24),
  (5, 'REPAIRS', 'Repairs / trades', 72),
  (6, 'PAINT', 'Paint', 48),
  (7, 'FLOORING', 'Flooring', 48),
  (8, 'DEEP_CLEAN', 'Deep clean', 24),
  (9, 'QA_PHOTOS', 'QA walkthrough + photos', 12),
  (10, 'RELIST', 'Relist', 0);

CREATE TEMP TABLE stage_vendor_seed (
  stage_code TEXT PRIMARY KEY,
  vendor_name TEXT NOT NULL
) ON COMMIT DROP;

INSERT INTO stage_vendor_seed (stage_code, vendor_name) VALUES
  ('NOTICE', 'Cedar Ridge in-house'),
  ('PRE_INSPECT', 'Cedar Ridge in-house'),
  ('MOVEOUT', 'Cedar Ridge in-house'),
  ('INSPECT_PUNCH', 'Cedar Ridge in-house'),
  ('TRASHOUT', 'QuickHaul Junk Removal'),
  ('REPAIRS', 'Dale Hutchins'),
  ('PAINT', 'Rivera Painting'),
  ('FLOORING', 'Statewide Flooring'),
  ('DEEP_CLEAN', 'Maria''s Cleaning Co'),
  ('QA_PHOTOS', 'Cedar Ridge in-house'),
  ('RELIST', 'Cedar Ridge in-house');

CREATE TEMP TABLE turn_seed (
  unit_label TEXT PRIMARY KEY,
  property_address TEXT NOT NULL,
  rent_monthly NUMERIC(10,2) NOT NULL,
  notice_date DATE,
  moveout_date DATE,
  target_ready_date DATE,
  current_stage_code TEXT NOT NULL,
  current_stage_activated_at TIMESTAMPTZ NOT NULL,
  completed_stage_codes TEXT[] NOT NULL
) ON COMMIT DROP;

INSERT INTO turn_seed VALUES
  ('12B', '418 Maple St', 1450.00, (now() - interval '18 days')::date, (now() - interval '6 days')::date, (now() - interval '1 day')::date, 'PAINT', now() - interval '4 days', ARRAY['NOTICE','PRE_INSPECT','MOVEOUT','INSPECT_PUNCH','TRASHOUT','REPAIRS']),
  ('14A', '418 Maple St', 1600.00, (now() - interval '16 days')::date, (now() - interval '4 days')::date, (now() + interval '2 days')::date, 'REPAIRS', now() - interval '2 days 6 hours', ARRAY['NOTICE','PRE_INSPECT','MOVEOUT','INSPECT_PUNCH','TRASHOUT']),
  ('3', '2201 Oak Ave', 1200.00, (now() - interval '9 days')::date, (now() - interval '2 days')::date, (now() + interval '3 days')::date, 'TRASHOUT', now() - interval '30 hours', ARRAY['NOTICE','PRE_INSPECT','MOVEOUT','INSPECT_PUNCH']),
  ('7', '2201 Oak Ave', 1325.00, (now() - interval '13 days')::date, (now() - interval '5 days')::date, (now() + interval '1 day')::date, 'FLOORING', now() - interval '6 hours', ARRAY['NOTICE','PRE_INSPECT','MOVEOUT','INSPECT_PUNCH','TRASHOUT','REPAIRS','PAINT']),
  ('12A', '418 Maple St', 1450.00, (now() - interval '21 days')::date, (now() - interval '8 days')::date, now()::date, 'QA_PHOTOS', now() - interval '8 hours', ARRAY['NOTICE','PRE_INSPECT','MOVEOUT','INSPECT_PUNCH','TRASHOUT','REPAIRS','PAINT','FLOORING','DEEP_CLEAN']),
  ('55', '55 Birch Ct', 2100.00, (now() - interval '1 day')::date, (now() + interval '6 days')::date, (now() + interval '10 days')::date, 'NOTICE', now() - interval '1 day', ARRAY[]::TEXT[]);

WITH inserted_turns AS (
  INSERT INTO "turn" (
    unit_label,
    property_address,
    rent_monthly,
    notice_date,
    moveout_date,
    target_ready_date,
    status,
    is_fixture,
    created_at
  )
  SELECT
    unit_label,
    property_address,
    rent_monthly,
    notice_date,
    moveout_date,
    target_ready_date,
    'active',
    TRUE,
    now() - interval '21 days'
  FROM turn_seed
  RETURNING id, unit_label
)
INSERT INTO turn_stage (
  turn_id,
  seq,
  stage_code,
  stage_name,
  status,
  vendor_id,
  sla_hours,
  activated_at,
  completed_at,
  completed_via,
  completed_by
)
SELECT
  it.id,
  st.seq,
  st.stage_code,
  st.stage_name,
  CASE
    WHEN st.stage_code = ts.current_stage_code THEN 'active'
    WHEN st.stage_code = ANY(ts.completed_stage_codes) THEN 'complete'
    ELSE 'pending'
  END AS status,
  v.id AS vendor_id,
  st.sla_hours,
  CASE
    WHEN st.stage_code = ts.current_stage_code THEN ts.current_stage_activated_at
    WHEN st.stage_code = ANY(ts.completed_stage_codes) THEN ts.current_stage_activated_at - ((array_position(ts.completed_stage_codes, st.stage_code) + 1) * interval '8 hours')
    ELSE NULL
  END AS activated_at,
  CASE
    WHEN st.stage_code = ANY(ts.completed_stage_codes) THEN ts.current_stage_activated_at - (array_position(ts.completed_stage_codes, st.stage_code) * interval '8 hours')
    ELSE NULL
  END AS completed_at,
  CASE
    WHEN st.stage_code = ANY(ts.completed_stage_codes) THEN
      CASE
        WHEN st.stage_code NOT IN ('NOTICE', 'MOVEOUT') THEN 'vendor_reply'
        ELSE 'manual'
      END
    ELSE NULL
  END AS completed_via,
  CASE
    WHEN st.stage_code = ANY(ts.completed_stage_codes) THEN
      CASE
        WHEN st.stage_code NOT IN ('NOTICE', 'MOVEOUT') THEN COALESCE(v.telegram_chat_id, 'fixture_vendor')
        ELSE 'seed'
      END
    ELSE NULL
  END AS completed_by
FROM inserted_turns it
JOIN turn_seed ts ON ts.unit_label = it.unit_label
CROSS JOIN stage_template_seed st
JOIN stage_vendor_seed sv ON sv.stage_code = st.stage_code
JOIN vendor v ON v.name = sv.vendor_name
ORDER BY it.unit_label, st.seq;

INSERT INTO event_log (turn_id, stage_id, actor_type, actor_id, channel, event_type, raw_text, parsed_json, created_at)
SELECT
  ts.turn_id,
  ts.id,
  'vendor',
  COALESCE(v.telegram_chat_id, 'fixture_vendor'),
  'telegram',
  'stage_complete',
  'fixture completion: ' || t.unit_label || ' ' || ts.stage_code,
  jsonb_build_object('fixture', true, 'stage_code', ts.stage_code),
  ts.completed_at
FROM turn_stage ts
JOIN "turn" t ON t.id = ts.turn_id
LEFT JOIN vendor v ON v.id = ts.vendor_id
WHERE t.is_fixture = TRUE
  AND ts.completed_via = 'vendor_reply';

INSERT INTO event_log (turn_id, stage_id, actor_type, actor_id, channel, event_type, raw_text, parsed_json, created_at)
SELECT
  ts.turn_id,
  ts.id,
  'manager',
  'seed',
  'seed',
  'manual_advance',
  'fixture manual completion: ' || t.unit_label || ' ' || ts.stage_code,
  jsonb_build_object('fixture', true, 'completed_via', 'manual'),
  ts.completed_at
FROM turn_stage ts
JOIN "turn" t ON t.id = ts.turn_id
WHERE t.is_fixture = TRUE
  AND ts.completed_via = 'manual';

INSERT INTO event_log (turn_id, stage_id, actor_type, actor_id, channel, event_type, raw_text, parsed_json, created_at)
SELECT
  t.id,
  ts.id,
  'system',
  'seed',
  'seed',
  'stage_seeded',
  'fixture current stage seeded',
  jsonb_build_object('fixture', true, 'current_stage_code', ts.stage_code),
  ts.activated_at
FROM "turn" t
JOIN turn_stage ts ON ts.turn_id = t.id AND ts.status = 'active'
WHERE t.is_fixture = TRUE;

INSERT INTO event_log (turn_id, stage_id, actor_type, actor_id, channel, event_type, raw_text, parsed_json, created_at)
VALUES
  ((SELECT id FROM "turn" WHERE unit_label = '12B' AND property_address = '418 Maple St' AND is_fixture = TRUE), (SELECT ts.id FROM turn_stage ts JOIN "turn" t ON t.id = ts.turn_id WHERE t.unit_label = '12B' AND t.property_address = '418 Maple St' AND ts.stage_code = 'PAINT' AND t.is_fixture = TRUE), 'vendor', 'placeholder_rivera_painting', 'telegram', 'reply_received', 'done with 12b', '{"fixture": true, "intent": "stage_complete"}', now() - interval '3 days 23 hours'),
  ((SELECT id FROM "turn" WHERE unit_label = '14A' AND property_address = '418 Maple St' AND is_fixture = TRUE), (SELECT ts.id FROM turn_stage ts JOIN "turn" t ON t.id = ts.turn_id WHERE t.unit_label = '14A' AND t.property_address = '418 Maple St' AND ts.stage_code = 'REPAIRS' AND t.is_fixture = TRUE), 'vendor', 'placeholder_dale_hutchins', 'telegram', 'reply_received', 'cant get there till thursday, sorry', '{"fixture": true, "intent": "delay_notice"}', now() - interval '1 day 6 hours'),
  ((SELECT id FROM "turn" WHERE unit_label = '3' AND property_address = '2201 Oak Ave' AND is_fixture = TRUE), (SELECT ts.id FROM turn_stage ts JOIN "turn" t ON t.id = ts.turn_id WHERE t.unit_label = '3' AND t.property_address = '2201 Oak Ave' AND ts.stage_code = 'TRASHOUT' AND t.is_fixture = TRUE), 'vendor', 'fixture_vendor', 'telegram', 'reply_received', 'on the way', '{"fixture": true, "intent": "stage_started"}', now() - interval '20 hours'),
  ((SELECT id FROM "turn" WHERE unit_label = '12A' AND property_address = '418 Maple St' AND is_fixture = TRUE), (SELECT ts.id FROM turn_stage ts JOIN "turn" t ON t.id = ts.turn_id WHERE t.unit_label = '12A' AND t.property_address = '418 Maple St' AND ts.stage_code = 'QA_PHOTOS' AND t.is_fixture = TRUE), 'vendor', 'fixture_vendor', 'telegram', 'reply_received', 'is the lockbox still there?', '{"fixture": true, "intent": "question"}', now() - interval '7 hours'),
  ((SELECT id FROM "turn" WHERE unit_label = '7' AND property_address = '2201 Oak Ave' AND is_fixture = TRUE), (SELECT ts.id FROM turn_stage ts JOIN "turn" t ON t.id = ts.turn_id WHERE t.unit_label = '7' AND t.property_address = '2201 Oak Ave' AND ts.stage_code = 'FLOORING' AND t.is_fixture = TRUE), 'vendor', 'fixture_vendor', 'telegram', 'reply_received', 'materials arrived', '{"fixture": true, "intent": "stage_started"}', now() - interval '5 hours'),
  ((SELECT id FROM "turn" WHERE unit_label = '12B' AND property_address = '418 Maple St' AND is_fixture = TRUE), (SELECT ts.id FROM turn_stage ts JOIN "turn" t ON t.id = ts.turn_id WHERE t.unit_label = '12B' AND t.property_address = '418 Maple St' AND ts.stage_code = 'PAINT' AND t.is_fixture = TRUE), 'vendor', 'placeholder_rivera_painting', 'telegram', 'reply_received', 'need one more coat', '{"fixture": true, "intent": "delay_notice"}', now() - interval '2 days'),
  ((SELECT id FROM "turn" WHERE unit_label = '14A' AND property_address = '418 Maple St' AND is_fixture = TRUE), (SELECT ts.id FROM turn_stage ts JOIN "turn" t ON t.id = ts.turn_id WHERE t.unit_label = '14A' AND t.property_address = '418 Maple St' AND ts.stage_code = 'REPAIRS' AND t.is_fixture = TRUE), 'vendor', 'placeholder_dale_hutchins', 'telegram', 'reply_received', 'patched drywall', '{"fixture": true, "intent": "stage_started"}', now() - interval '1 day'),
  ((SELECT id FROM "turn" WHERE unit_label = '3' AND property_address = '2201 Oak Ave' AND is_fixture = TRUE), (SELECT ts.id FROM turn_stage ts JOIN "turn" t ON t.id = ts.turn_id WHERE t.unit_label = '3' AND t.property_address = '2201 Oak Ave' AND ts.stage_code = 'TRASHOUT' AND t.is_fixture = TRUE), 'vendor', 'fixture_vendor', 'telegram', 'reply_received', 'need access to the side gate', '{"fixture": true, "intent": "question"}', now() - interval '10 hours');

COMMIT;
