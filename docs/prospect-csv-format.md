# Prospect Turn CSV Format

Use this format only for fictional or prospect-provided turn summaries. Do not commit real prospect CSVs.

Required columns:

- `unit_label`
- `property_address`
- `rent_monthly`
- `notice_date`
- `moveout_date`
- `target_ready_date`
- `current_stage_code`
- `current_stage_activated_at`

Optional completion timestamp columns:

- `notice_completed_at`
- `pre_inspect_completed_at`
- `moveout_completed_at`
- `inspect_punch_completed_at`
- `trashout_completed_at`
- `repairs_completed_at`
- `paint_completed_at`
- `flooring_completed_at`
- `deep_clean_completed_at`
- `qa_photos_completed_at`
- `relist_completed_at`

Accepted `current_stage_code` values are the stage codes in `fixtures/stage-template.json`.

Imported rows are written with `is_fixture = false`. `scripts/reset-demo.ps1` refuses to run while any non-fixture turn or vendor exists.
