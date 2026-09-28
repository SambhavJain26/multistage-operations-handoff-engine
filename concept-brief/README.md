# Make-Ready Sequencing Solution Brief

A prospect-personalized, 4-page square executive solution brief for the Make-Ready Sequencing Automation.

Built for property management executives, vice presidents of operations, and turnover leaders. It answers four core business questions in a clean, restrained, high-contrast format:

1. **What problem does this solve, and what changes?** (Page 1: Turnover coordination lag, trade silence, rework costs, before vs. after comparison).
2. **What does the system actually do from start to finish?** (Page 2: Notice to rent-ready flow, actor badges, deterministic sequence guard, manager decision gate, and role boundaries).
3. **What tools connect, what moves between them, and what must be confirmed?** (Page 3: 3-zone architecture schematic: existing PMS & inspection tools, proposed client-owned private core, external messaging channels, and confirmed/to-confirm integration routes).
4. **What do people still decide, how is the system controlled, and what should we expect?** (Page 4: Daily operating queues, human authority, fail-safe fallbacks, what a production pilot measures, and meeting CTA).

---

## File Structure

```text
concept-brief/
├── assets/
│   ├── fonts/                   # Local licensed variable fonts (Geist & Manrope)
│   └── icons/                   # Lucide license and icon definitions
├── fixtures/
│   └── prospect-data.qa.json    # Complete fictional prospect fixture for testing
├── scripts/
│   └── render-brief.cjs         # Playwright validation and PDF generator script
├── make-ready-solution-brief.html      # 4-page HTML template with data-prospect hooks
├── make-ready-solution-brief.css       # Complete square print & screen stylesheet
├── make-ready-solution-brief-icons.js  # Clean SVG icon injector
├── prospect-data.template.json         # Reusable template data file with placeholders
└── README.md                    # This guide
```

Generated outputs:
- **PDFs**: `output/pdf/<slug>-make-ready-solution-brief.pdf`
- **QA Screenshots**: `tmp/brief-qa/<slug>/page-{1..4}.png`

---

## Step-by-Step: Creating a New Prospect Brief

### Step 1: Create the Prospect Data File

Copy the template file to a new prospect JSON file:

```powershell
Copy-Item concept-brief/prospect-data.template.json concept-brief/prospects/acme-residential.json
```

*(You can store prospect JSON files in `concept-brief/prospects/` or any local folder outside version control).*

### Step 2: Fill in Verified Prospect Information

Edit the JSON file with verified research. Follow these rules:

- **`slug`**: A short lowercase alphanumeric hyphenated name (e.g. `"acme-residential"`). Used in output filenames.
- **`company`**: The official company name (e.g. `"Acme Residential Partners"`).
- **`decisionMaker`**: Full name of the decision maker (e.g. `"Sarah Jenkins"`).
- **`research.reviewed`**: An array of 1 to 3 short, punchy source labels (e.g. `["1,400 doors across 8 assets", "Centralized turnover team", "Public careers review"]`).
- **`research.note`**: A 1–2 sentence observation connecting their specific door count/operating structure to turnover handoff lag (under 300 characters).
- **`research.evidence`**: Array of `{ "fact": "...", "source": "..." }`. **Kept strictly internal for fact verification; never rendered into the PDF.**
- **`systems`**: Known PMS, inspection tool, manager channel, vendor channels, and reporting tool. If unknown, leave as clean concise labels like `"[To confirm with client]"` or `"[Client PMS]"`.
- **`routes`**: Integration routes to confirm (intake, PMS read/write, inspection, manager cards, vendor SMS/email, reporting sync).

### Step 3: Run the Render Script

Execute the generator from the project root:

```powershell
node concept-brief/scripts/render-brief.cjs --data concept-brief/prospects/acme-residential.json
```

To render the reusable template with default placeholders:

```powershell
node concept-brief/scripts/render-brief.cjs
```

### Step 4: Review Validation & Output

The script executes automated quality and safety gates:
1. **Field validation**: Ensures required fields are populated and prevents exporting unresolved bracketed placeholders like `[Client Company]`.
2. **File protection**: Prevents overwriting the reusable template PDF or prior baseline PDFs.
3. **DOM geometry verification**: Verifies that exactly 4 pages render at 864px × 864px (9in × 9in), with zero escaped elements, zero clipped text, and no tight inner margins (<8px).
4. **Screenshots**: Automatically saves high-resolution PNGs of all 4 pages into `tmp/brief-qa/<slug>/`.
5. **PDF generation**: Exports the tagged print PDF to `output/pdf/<slug>-make-ready-solution-brief.pdf`.

---

## Safety & Architectural Invariants

- **Production authority**: Capabilities described in the brief match the production blueprint (`docs/production-make-ready-sequencing-blueprint.md`), not a temporary demo or prototype shortcut.
- **Zero autonomous vendor messages**: The brief clearly specifies that every outgoing contractor message requires manager channel selection (Email, Message, Both).
- **Authoritative state**: PostgreSQL is the durable source of truth. External dashboards (Airtable) and PMS connections are mirrors; mirror downtime never halts sequence enforcement.
- **Text-only rendering**: Prospect values are injected into DOM nodes via `textContent`, never `innerHTML`.
- **Internal evidence isolation**: Confidential operator research notes and URLs in `research.evidence` remain in the JSON file and are never exposed in the generated PDF.
- **Meeting CTA**: Uses the verified scheduling link (`https://cal.com/sambhav-builds/pm-automation-audit`) with clear contact attribution (`Sambhav Jain / sambhav@sambhavbuilds.com`).
