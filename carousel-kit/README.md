# Carousel Kit

Everything needed to build LinkedIn document carousels in the marked-up-document
style, in any project. Drop this folder into a repo, point Claude at it, and the
decks it produces will match the ones already built.

## What's here

```
<your project root>/
├── .claude/skills/linkedin-carousel/SKILL.md   ← the skill. Loads automatically
├── PROMPT.md                 ← paste this into a new chat session
└── carousel-kit/
    ├── design-system.md      ← read this first. The rules, and why each exists
    ├── carousel-template.css ← the design itself. Every colour, size and layout
    ├── examples/             ← four finished decks. Clone their structure
    │   ├── post-01-what-ai-should-touch.html
    │   ├── post-04-what-ai-reading-costs.html
    │   ├── post-07-twelve-things-wrong.html
    │   └── post-13-questions-to-ask.html
    ├── scripts/
    │   ├── preview-carousel.ps1  ← PNG contact sheet, or one slide full size
    │   └── render-carousel.ps1   ← the upload-ready PDF
    └── out/                  ← rendered PDFs land here
```

Copy the **contents** of this starter into your project root, so that `.claude/`
sits at the root rather than inside `carousel-kit/`. Claude Code only discovers
skills at the project root, so a `.claude/` folder nested one level down is
silently ignored — the deck would still get built, but off whatever design the
session invented instead of this one.

**New decks go in the kit root**, next to `carousel-template.css`, so they link
the stylesheet as `href="carousel-template.css"`. The examples sit one level
down and link `../carousel-template.css`; the scripts skip `examples/` unless
you name a deck explicitly with `-Name`.

## Using it

Open a session in the project root. The `linkedin-carousel` skill loads
automatically and should trigger on any request to build or fix a carousel; if it
does not, paste `PROMPT.md`, which carries the same instructions and works on its
own. Then:

```bash
.\carousel-kit\scripts\preview-carousel.ps1
```

```bash
.\carousel-kit\scripts\render-carousel.ps1
```

`preview` writes a PNG to your temp directory and prints the path — a contact
sheet by default, or `-Slide 5` for one slide at full size. Look at both views;
each hides what the other shows. `render` writes the PDF to `out/` and verifies
it: page count against slide count, page dimensions, embedded font subsets, and
image count. It warns rather than failing silently when something is off.

Both need **Chrome or Edge** and **network access** — the two typefaces load
from `api.fontshare.com` at render time, and a failed fetch falls back to a
system face without erroring, which is easy to miss.

### Without PowerShell

If you're somewhere the scripts can't run, open the deck's HTML in Chrome and
print it: `Ctrl+P` → Destination **Save as PDF** → Margins **None** → **Background
graphics ON**. The stylesheet's `@page` rule sets the size, so the result is the
same 1080x1350. Background graphics is not optional — without it the cream
ground, the ruled lines and every marker swipe drop out.

## Adapting it to a different brand

The palette is the only part that is anyone's to change. `design-system.md`
carries the colour table and the semantic roles beneath it; edit those and the
matching custom properties at the top of `carousel-template.css`, and leave
everything else alone. The layouts, the 24px baseline grid, the annotation
vocabulary and the grain are all independent of colour.

If you do change it, keep the **colour rule** intact, because it is what stops
the deck looking arbitrary: type is always ink, and colour only ever appears as
an annotation on top of type, or as the page number.

## Two things that will bite

**The grain must stay a baked PNG tile.** It is embedded once as a data URI in
the stylesheet. If anyone replaces it with an `feTurbulence` SVG filter — which
looks like the tidier way to do it — Chrome evaluates the filter at output
resolution and bakes a full-page bitmap into every slide. That takes the PDF
from ~130 KB to ~24 MB for visually identical output. `render-carousel.ps1` warns if it sees more than one image object in the PDF, which is the symptom.

**Every leading is a multiple of 24px.** That is what puts the type on the ruled
lines. Changing a type size means checking its leading still divides by 24, or
the text drifts off the grid and the page stops looking constructed.

## Provenance

Built for a vendor-paperwork automation project, 2026-08. The design decisions
and the failure modes behind them are recorded in `design-system.md` — it is
worth reading in full before changing anything, because most of the rules exist
because something looked broken first.
