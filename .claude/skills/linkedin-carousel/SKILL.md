---
name: linkedin-carousel
description: Build a LinkedIn document carousel from finished post copy using the fixed template in carousel-kit/, and render it to an upload-ready PDF. Use this whenever the user asks to build, render, design, lay out, fix or restyle a carousel, a document post, a deck or its slides — including when they name a post number, mention the cover slide, the payoff slide, the annotation marks, the grain, or the carousel template, or ask why a slide looks wrong. Use it even if they never say the word "carousel"; if the work touches carousel-kit/, this skill applies.
---

# Building a LinkedIn carousel

You are turning finished copy into an eight-ish page PDF at 1080x1350, uploaded
to LinkedIn as a document post. The writing is already done and signed off. Your
job is layout, annotation, and getting it to render cleanly.

## Read these first

Do not skip the first one. This skill deliberately does not restate the design
system, because a copy would drift out of sync with the stylesheet that actually
governs it.

| File | What it gives you |
|---|---|
| `carousel-kit/design-system.md` | **The design system.** Palette and the rule governing where colour may appear, the two typefaces, all nine layouts, the annotation vocabulary, the baseline grid, and a list of failure modes with their real causes. Source of truth |
| `carousel-kit/examples/` | Four finished decks. Find the one closest in shape to what you are building and clone its structure — the `<head>`, the slide shells, the footer, and the baseline-snap script at the foot |
| `carousel-kit/carousel-template.css` | The stylesheet. The only place sizes, colours and spacing live |

Most rules in the design system exist because something looked broken first.
Read it in full before changing anything in the stylesheet.

New decks go in the **kit root**, next to `carousel-template.css`, linking it as
`href="carousel-template.css"`. The examples sit one level down and link
`../carousel-template.css`.

## The copy is final

You may **line-break** a sentence, **split a run of items** into list elements,
and **choose which phrase carries a mark**. Those are formatting decisions.

You may not change a word, reorder a sentence, add a connective, or trim to fit.
Post copy is normally checked against a banned-word list, an em-dash budget and a
character count at the fold before it reaches you. Editing to make the layout
easier silently breaks checks you cannot see.

If copy genuinely will not fit, drop a type size step — the design system records
that a long line does exactly that rather than overrunning — or say plainly that
the slide is overset and let the user decide.

## Workflow

1. **Read the copy and any production note attached to it.** A note saying a
   particular slide should get the most air is a decision someone already made
   about the argument, and the layout has to honour it.
2. **Find the deck's payoff word before anything else.** Every deck gets one
   word of Zodiak if the copy can carry it. Look for one word, ending its
   sentence, and **nine characters or fewer** — that is measured, not a guess:
   "evidence." fills the column with 16px to spare and "emergency." clips.
   Check the inverted slide first. If the deck's landing word sits there, the
   payoff and the spike share one frame and the mark goes gold, which is the
   strongest thing this template does; the kit's post 1 example is the
   reference. Otherwise take it wherever the copy lands, often the close. If
   nothing passes, say so rather than forcing a word in.
   This step is first because it is the one that gets skipped: a deck shipped
   with no Zodiak in it at all because the notes described how to set a payoff
   without ever saying to go looking for one.
3. **Map each slide to a layout.**
4. **Write the HTML.** Content and layout classes only. Never a `style`
   attribute, never a `<style>` block, never a class the stylesheet does not
   define.
5. **Copy the baseline-snap script verbatim** from the foot of any example into
   the new file. Without it the centred content lands off the ruled grid.
6. **Preview and actually look at it.**
7. **Fix and re-render** until it holds.
8. **Render the PDF** and check what the script reports.

## Mapping slides to layouts

Read a slide's copy and ask what shape it is. Full descriptions are in the design
system; this is how to choose.

| The copy looks like | Layout |
|---|---|
| Two beats, split by a blank line | **Statement** — `.lead` `.divider` `.turn` |
| A statement then a run of short nouns | **Field list** — `.lead` `.tags` `.divider` `.turn` |
| Numbered conditions or checks | **Check list** — `.head` `.checks` |
| One list split by severity across several slides | **Grouped list** — `.group` `.checks` |
| A statement too long for `.lead` and too load-bearing for `.turn` | **Claim** — `.claim`, optionally `.lead-in` |
| A slide whose subject is a number | **Figure** — `.lead-in` `.fig` `.lead-out` |
| A heading and a one-word answer | **Payoff** — `.head` `.pay` `.margin-note` |
| A sentence the slide has built to, ending on one word | **Payoff, statement-led** — `.claim` `.divider` `.lead-in` `.pay` |
| First slide | **Cover** — `.display` `.kicker` |
| Last slide | **Close** — `.close-lead` `.divider` `.turn` `.byline` |

**When no layout fits, add one.** Add it to `carousel-template.css`, document it
in `design-system.md`, and **add its `.slide--invert` colours in the same pass** —
a layout is not finished until it works on the dark slide, and several were
shipped broken because nothing had needed them there yet. Do not solve it inline
in the post HTML; the stylesheet is the only place sizes, colours and spacing
live, and a post that breaks that rule forks the design without anyone noticing.

## Choosing the marks

This is the actual craft, and it is where a deck either reads as designed or as
decorated. The marks are the argument made visible: a reader should be able to
skim only the marked words and come away with the post.

**Decide every mark from the sentence it sits on.** The vocabulary below is
semantic, not a set of styles to rotate through. Read what the copy is doing —
asserting, denying, questioning, naming — and take the device that means it.
Two slides land on the same device when the copy earns it, and on different
devices when it does not. That is the whole method, and everything after it is
mechanics.

Three things this rules out, all of which have actually happened here:

- **Copying the previous deck.** A payoff word was circled on one deck purely
  because the kit's example circles its own. The right mark was the underline:
  that sentence was an affirmation, and the example's is a provocation.
- **Copying the previous slide.** A device that fits slide 4 has no claim on
  slide 5. Marks repeat across a deck because meanings repeat, not for rhythm.
- **Applying a suggestion uniformly.** When someone proposes a treatment —
  circle it, box it, use the italic — that is a candidate to test on the slides
  where it might fit, not an instruction to roll out across every deck. Build
  it, render it, keep it where it reads and say plainly where it does not.

- **Marker** (`.hl`) — the load-bearing phrase, the thing the slide turns on.
  The deck's most-used signal; it should mean exactly one thing throughout.
- **Circle** (`.pen--circle`) — a word held up for scrutiny. **One word.**
  Stretched over a phrase it flattens into a wide ellipse that overshoots the
  last word and cuts through the first, and stops looking drawn. If a phrase
  needs marking, that is what the marker is for.
- **Underline** (`.pen--under`) — affirmation.
- **Strike** (`.pen--strike`) — negation.
- **Selection box** (`.sel`) — once per deck, on the cover, on the word the whole
  post is about.

When the deck is finished, count the devices. The marker should lead; it is the
workhorse. But a set where a second device never appears has stopped reading the
copy, and two decks with identical tallies usually means the second one was
built from the first rather than from its own script.

Rules that come from real mistakes:

- **A pen mark cannot span a line break.** `.pen` is an inline-block, so a phrase
  too wide for the line wraps inside it while the stroke covers only part. Mark
  one word, use `.nb`, or drop a size step. `.hl` is exempt — it paints as a
  background and clones onto every line box.
- **Parallel copy gets parallel marks.** Mirrored sentences take the same device,
  each with a slightly different hand-drawn path, because a person drew them.
- **Every slide carries at least one mark.** In a deck whose identity is the
  annotation layer, a bare page reads as something forgotten.
- **Two marks per slide is the ceiling.** The cover can take three.
- **Check any highlight on an inverted slide.** The swipe is sized to overhang a
  word rather than enclose it, so on the dark ground the uncovered ascenders
  become dark ink on dark navy and vanish. The stylesheet corrects for this;
  confirm it actually worked.

## The verify loop

Render, look, fix. Do not skip the looking — every defect in the first build of
this template was caught by eye and none by reasoning about the CSS.

```bash
.\carousel-kit\scripts\preview-carousel.ps1
```

```bash
.\carousel-kit\scripts\preview-carousel.ps1 -Slide 6
```

Then read the PNG it writes. **Look at both views.** A contact sheet shows
composition and rhythm but hides clipping, low contrast and misplaced marks. A
full-size slide shows the marks but says nothing about how the set reads. Things
have repeatedly looked fine in one and broken in the other.

Check for: punctuation sitting apart from the word before it; a mark on the wrong
word or floating off its line; type running off an edge or clipped by its own
circle; a slide much fuller or emptier than its neighbours; text drifting off the
ruled lines; anything crossing the footer band.

## Failure modes

The symptom is what you see; the cause is rarely what you would guess from it.

**Punctuation detaches after a highlighted phrase.** `.hl` adds horizontal
padding so the swipe overhangs the glyphs; that padding must be cancelled by an
equal negative margin or it shoves the next character sideways.

**A sentence in a list tears in half.** A flex container turns an inline `.pen`
span into its own flex item. Position the numeral instead of flexing the row —
`.checks` shows how.

**A grid becomes visible across the page.** The grain tile carries large-scale
light and dark regions and they repeat. The tile must be high-passed: subtract a
heavily blurred copy so only fine noise survives.

**The PDF comes out at 20 MB or more.** The grain is an `feTurbulence` filter.
Filters are evaluated at output resolution, so Chrome bakes a full-page bitmap
into every slide. It must be a baked PNG tile, embedded once and repeated — a
185x difference for identical output.

**The render writes nothing and reports no exit code.** `chrome.exe` was invoked
directly, so the command line went to an already-running Chrome. Use
`Start-Process -Wait -PassThru` with a throwaway `--user-data-dir`, as both
scripts do.

**Type sits off the ruled lines.** A leading is no longer a multiple of the 24px
baseline unit. Changing any type size means checking its leading still divides.

**Content is stranded in the upper third with a dead page below.** The content
block is centred in a bounded band, not top-anchored. If a slide looks
top-heavy the copy is short and the type is too small, not misaligned.

**Everything renders in a system serif.** The webfonts did not load. Both faces
come from `api.fontshare.com` at render time and a failed fetch falls back
silently rather than erroring.

**A page count looks lower than the slide count.** Read it from the number of
page objects, not from the first `/Count` in the PDF — past about eight pages
Chrome splits the page tree and the first `/Count` is a subtree. The render
script already does this correctly and warns on a genuine mismatch.

## Finishing

```bash
.\carousel-kit\scripts\render-carousel.ps1
```

The script verifies and reports: page count against slide count, page
dimensions, embedded font subsets, and image count. **Exactly one image object
is correct** — that is the grain tile. More than one means the grain has
regressed to a filter. Fewer than two font subsets means the webfonts did not
load.

Tell the user two things when you hand it over. LinkedIn asks for a **document
title** on upload and displays it in the feed, so it should be the cover line
rather than a filename. And show them the contact sheet, saying what you changed
and anything you are unsure about — if you added a layout, say so explicitly and
show that slide at full size.
