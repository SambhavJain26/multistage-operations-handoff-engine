BEGIN;
SET LOCAL client_min_messages = warning;

CREATE TABLE IF NOT EXISTS vendor (
  id               SERIAL PRIMARY KEY,
  name             TEXT NOT NULL,
  trade            TEXT NOT NULL CHECK (trade IN ('paint', 'clean', 'flooring', 'repairs', 'trashout', 'inspect')),
  telegram_chat_id TEXT UNIQUE,
  phone_e164       TEXT,
  consent_source   TEXT,
  consent_at       TIMESTAMPTZ,
  opted_out_at     TIMESTAMPTZ,
  active           BOOLEAN NOT NULL DEFAULT TRUE,
  is_fixture       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (name, trade)
);

CREATE TABLE IF NOT EXISTS "turn" (
  id                SERIAL PRIMARY KEY,
  unit_label        TEXT NOT NULL,
  property_address  TEXT NOT NULL,
  rent_monthly      NUMERIC(10,2) NOT NULL CHECK (rent_monthly >= 0),
  notice_date       DATE,
  moveout_date      DATE,
  target_ready_date DATE,
  status            TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'complete', 'cancelled')),
  is_fixture        BOOLEAN NOT NULL DEFAULT TRUE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (unit_label, property_address, is_fixture)
);

CREATE TABLE IF NOT EXISTS turn_stage (
  id              SERIAL PRIMARY KEY,
  turn_id         INT NOT NULL REFERENCES "turn"(id) ON DELETE CASCADE,
  seq             INT NOT NULL CHECK (seq BETWEEN 0 AND 10),
  stage_code      TEXT NOT NULL,
  stage_name      TEXT NOT NULL,
  status          TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'complete', 'skipped', 'blocked')),
  vendor_id       INT REFERENCES vendor(id),
  sla_hours       INT NOT NULL CHECK (sla_hours >= 0),
  activated_at    TIMESTAMPTZ,
  completed_at    TIMESTAMPTZ,
  completed_via   TEXT CHECK (completed_via IN ('vendor_reply', 'manual', 'override', 'skip')),
  completed_by    TEXT,
  alerted_at      TIMESTAMPTZ,
  snooze_until    TIMESTAMPTZ,
  evidence_photo  TEXT,
  UNIQUE (turn_id, seq),
  UNIQUE (turn_id, stage_code),
  CHECK (
    (status IN ('complete', 'skipped') AND completed_at IS NOT NULL AND completed_via IS NOT NULL)
    OR (status NOT IN ('complete', 'skipped'))
  )
);

CREATE TABLE IF NOT EXISTS outbound_queue (
  id          SERIAL PRIMARY KEY,
  turn_id     INT REFERENCES "turn"(id) ON DELETE CASCADE,
  stage_id    INT REFERENCES turn_stage(id) ON DELETE CASCADE,
  vendor_id   INT REFERENCES vendor(id),
  channel     TEXT NOT NULL DEFAULT 'telegram' CHECK (channel IN ('telegram', 'generic', 'board', 'digest')),
  draft_text  TEXT NOT NULL,
  status      TEXT NOT NULL DEFAULT 'awaiting_approval' CHECK (status IN ('awaiting_approval', 'sent', 'held', 'rejected')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  decided_at  TIMESTAMPTZ,
  sent_at     TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS event_log (
  id          SERIAL PRIMARY KEY,
  turn_id     INT,
  stage_id    INT,
  actor_type  TEXT CHECK (actor_type IN ('vendor', 'manager', 'system')),
  actor_id    TEXT,
  channel     TEXT CHECK (channel IN ('telegram', 'generic', 'board', 'digest', 'seed', 'import')),
  event_type  TEXT NOT NULL CHECK (
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
      'prospect_imported'
    )
  ),
  raw_text    TEXT,
  parsed_json JSONB,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_stage_active ON turn_stage(status, activated_at);
CREATE INDEX IF NOT EXISTS idx_stage_turn_status ON turn_stage(turn_id, status);
CREATE UNIQUE INDEX IF NOT EXISTS uniq_one_active_stage_per_turn ON turn_stage(turn_id) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_vendor_chat ON vendor(telegram_chat_id);
CREATE INDEX IF NOT EXISTS idx_vendor_fixture ON vendor(is_fixture, active);
CREATE INDEX IF NOT EXISTS idx_turn_fixture_status ON "turn"(is_fixture, status);
CREATE INDEX IF NOT EXISTS idx_turn_unit_address ON "turn"(lower(unit_label), lower(property_address));
CREATE UNIQUE INDEX IF NOT EXISTS uniq_outbound_awaiting_per_stage_vendor
  ON outbound_queue(stage_id, vendor_id)
  WHERE status = 'awaiting_approval';
CREATE INDEX IF NOT EXISTS idx_event_created ON event_log(created_at);
CREATE INDEX IF NOT EXISTS idx_event_stage ON event_log(stage_id);
CREATE INDEX IF NOT EXISTS idx_event_turn ON event_log(turn_id);
CREATE INDEX IF NOT EXISTS idx_event_metrics ON event_log(actor_type, event_type, created_at);

COMMIT;
