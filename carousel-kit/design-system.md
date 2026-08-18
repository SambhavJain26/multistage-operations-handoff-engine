# Carousel Design System

The fixed template behind every LinkedIn document carousel built with this kit.
`carousel-template.css` is the single source of truth; per-post HTML supplies
content and picks layout classes only, and must never introduce its own sizes,
colors, or spacing. If a post needs something the stylesheet cannot express, add
a named layout here and to the stylesheet so later posts inherit it.

Render with `.\scripts\render-carousel.ps1`. Page size is 1080x1350 (4:5), the
tallest ratio LinkedIn renders predictably in-feed on mobile, which is where
these get read.

Posts 1, 4, 7 and 13 are referenced throughout as worked examples. Their HTML is
in `examples/`; read the one closest to the shape you are building.

## The concept: the marked-up document

The deck looks like a page somebody has been over with a highlighter and a
pen. Marker swipes, circled words, an underline, a strike-through, and one
word boxed like an object picked up in a design tool.

This is not decoration. The subject of this work is documents that a person
reads and annotates, so the annotation layer *is* the argument, and it is
what stops a type-only deck reading as generic. It also gives every slide a
second element without needing photography, icons, or illustration.

**Nothing is a clean rectangle.** The marker swipe has uneven top and bottom
edges, the circles are drawn as open loops that overshoot, the underline is
two strokes at different opacities. If a mark looks machine-made it has
failed.

**The page is ruled, horizontally and vertically.** Faint horizontal lines
every 72px plus one vertical margin rule at 56px, the way a notebook page is
ruled. The vertical stroke is what makes the horizontal ruling read as a grid
somebody printed rather than a texture somebody applied.

## Palette

Owner-supplied, 2026-08-02. If you are adapting this kit for a different
brand, this table and the semantic roles beneath it are the only part you should
change. Everything else — the layouts, the grid, the annotation vocabulary, the
grain — is independent of the colours.

**Primary** `#3563CA` · **Secondary** `#CA9C35`

| Blue | Gold | Neutral |
|---|---|---|
| `#C9D7F0` | `#FDF0D6` | `#EDEFF0` |
| `#96B0E3` | `#F8C043` | `#C2C9CC` |
| `#6389D6` | `#CA9C35` | `#9BA3A8` |
| `#3563CA` | `#A17C28` | `#7B8285` |
| `#1F4393` | `#77581B` | `#595F61` |
| `#0E2455` | `#4C390E` | `#383B3D` |
| `#02081F` | `#251A04` | `#191B1C` |

### The color rule

One rule, and it removes every "is this intentional" question:

> **Type is always ink. Color only ever appears as an annotation on top of
> type, or as the page number.**

Every word on every slide is `#02081F` or `#383B3D`. Nothing else. Color
enters only as a marker swipe, a pen stroke, or the selection box — that is,
only as something a person added on top of a finished page. Page furniture —
the horizontal ruling and the vertical margin rule — is an ink tint, because
it is printed rather than added by hand.

| Value | Role |
|---|---|
| `#FDF0D6` | The ground. Every slide |
| `#02081F` | All display type, everywhere |
| `#383B3D` | Running detail copy |
| `#7B8285` | Eyebrow, footer deck title |
| `#F8C043` | The highlighter swipe. Byline rule |
| `#3563CA` | The pen. Circles, underlines, strikes, the selection handles, page number |
| `#1F4393` | The selection box fill. Once per deck, on the cover |
| Everything else | Reserved. Defined in the stylesheet for a deck that needs to look unlike this one |

## Type

Two families.

| Role | Family | Weights |
|---|---|---|
| Everything | **Switzer** | 900 display · 800 lead · 600 turn/checks · 400 detail · 700 micro |
| The second voice: the payoff word, and nothing else | **Zodiak** italic | 800 |

Both from Fontshare, loaded at render time, so the render machine needs
network access. A failed fetch falls back to a system face silently rather
than erroring, so check a rendered slide before publishing.

**Deliberately dropped, with reasons.** Clash Display — its period is an
oversized square that wrecks every sentence ending. Boska italic — too light
to hold against a black grotesque. IBM Plex — safe rather than wrong, and
safe is what made the first pass boring. Inter, Roboto, Helvetica, Arial,
Open Sans, Poppins, Montserrat — the generic-template tells.

## Layouts

| Layout | Classes |
|---|---|
| Cover | `.display` `.kicker` |
| Statement | `.lead` `.divider` `.turn` |
| Field list | `.lead` `.tags` `.divider` `.turn` |
| Check list | `.head` `.checks` |
| Grouped list | `.group` `.checks` · `.checks--marked` |
| Claim | `.claim`, optionally `.lead-in` above |
| Figure | `.lead-in` `.fig` `.lead-out` |
| Payoff | `.head` `.pay` `.margin-note` |
| Close | `.close-lead` `.divider` `.turn` `.byline` |

**Grouped list is for one list split by severity across several slides.** Post 7
runs twelve flags over six slides in two groups. The `.group` label sits under a
rule heavier than the hairline between rows, so it reads as a boundary rather
than another row, and the numerals hold one left column on every slide of the
group, so a slide carrying no label still belongs to it. Label sentences are set
at turn size rather than as a `.head`, because they are sentences the writer
wrote and 18px furniture buries them.

**The numerals are one treatment across the whole list.** An earlier pass gave
the first group swiped numerals and the second plain ones, to carry the severity
split visually. Owner's call, 2026-08-03: all twelve read the same, and the
labels and their rules carry the split on their own. `.checks--marked` is
therefore a numeral treatment, not a severity signal — do not reach for it to
mean "worse". Post 1 keeps plain `.checks`, so the modifier is what a deck opts
into rather than something `.checks` does by default.

**Claim is a statement too long for `.lead` and too load-bearing for `.turn`.**
The band holds seven and a half lines of `.lead`, so a statement much past a
hundred characters needs eight and overruns. Dropping it to `.turn` is worse
than the overset: it makes a slide carrying a whole claim on its own the
quietest slide in the deck. `.claim` sits between them at 78px on a 96px
leading. Post 13's matched pair uses it on both halves, so the only difference
between those two slides is the words, with `.lead-in` above the first to
introduce the pair.

**Nothing in the system is raster.** A `.shot` image layout was built for post
13's receipt slide and removed the same day: owner's call, 2026-08-04, no
screenshots in these decks. Type is vector with embedded font subsets and every
mark is a vector shape, so the only bitmap in a rendered PDF is the grain tile.
If a deck ever needs an artifact again, state it in prose rather than drawing a
frame that imitates an interface — a post about not faking your evidence cannot
be the one that ships a mocked-up screenshot.

**A copy deck that briefs a screenshot is briefing a stage direction, not
copy.** Problem-Proof decks end on a "receipt" slide and the script will carry a
bracketed line like `[Screenshot: both requests as classified]` above the real
sentences. That line is an instruction to the producer and is not set. The
sentences under it are the copy, they go in a Close, and the slide is the one
the deck inverts — which is also how it keeps the production note that the last
slide should break the pattern. Post 13 established this; build 2 post 1 is the
second instance, and posts 8 and 12 will each hit it again.

**`.lead-in` also works as a label above a `.lead`.** Named for the quiet line
either side of the thing it frames, it is not restricted to figures and claims.
Build 2 post 1 uses it to carry "Under-response, as the industry documents it:"
and "Over-response:" above the money sentence on two consecutive slides, which
makes a pair of slides structurally identical when their copy is parallel. Note
the baseline-snap script measures the first listed element in document order, so
the `.lead-in` becomes the probe host — that is correct and needs nothing.

**A long line drops a size step rather than overrunning.** The display sizes
assume short lines. Past roughly forty characters `.close-lead` runs to five
lines at 112px, overruns the `.body--close` band and pushes the turn into the
byline — post 7's close did exactly that, and post 13's cover did the same at
`.display`. Drop one step, to `.lead` in both cases, and the slide gets the air
it was supposed to have. Everything else about the layout is unchanged.

**A mark cannot span a line break inside `.pen`.** `.pen` is an inline-block, so
a phrase too wide for the line wraps *inside* it while the stroke, positioned
against the box, covers only part. Post 13's cover struck a five-word quoted
question at display size and the stroke landed on line one alone. Mark one word,
or use `.nb`, or drop a size step. `.hl` is exempt: it paints as a background
and clones onto every line box.

**`.lead-in` and `.lead-out` are framing type, not a size step.** They are
600-weight at 62px, the same as `.kicker`, so a slide that runs `.fig` over both
of them has a giant numeral and then two paragraphs at identical size and
weight — no hierarchy at all under the figure, while every other cover in a set
runs a heavy statement over a lighter kicker. Build 2 post 8's cover shipped a
draft that way. Use them where they genuinely frame the number; where the line
under a figure is a statement in its own right, it takes `.claim`, which gives
three descending steps at 208, 78 and 62. `.lead` at 96px was tried there and
crowds the page. `.fig + .claim` and `.fig + .lead` carry the 48px gap, since
neither class has a margin of its own.

**Figure is for a slide whose subject is a number.** The numeral runs at 208px
and the sentence framing it is deliberately quiet, so the number is read first
and the sentence only explains it. A statement layout cannot do this: its lead
and turn are sized for prose, and a figure set at prose size stops being the
point of the slide. `.lead-in` and `.lead-out` are the same treatment above
and below the figure, because they are one sentence either side of a number
rather than two voices. Post 4 opens on `$0.002` this way.

**And a third: `.lead-in` `.pay` `.divider` `.turn`, where the payoff opens the
slide.** Build 3 post 1's slide 2 lands on "name." in its *first* sentence and
carries three more after it, and the copy is not reordered, so the payoff cannot
close the slide. Setting the run-up and the word at the top and the remaining
sentences in a `.turn` behind a `.divider` reads as the spike and then the
explanation, and it introduces nothing: the original Payoff layout already puts
a `.margin-note` under a `.pay`, and this only substitutes the standard turn
treatment for that note. No new sizes, spacing or `.slide--invert` declarations
are needed, since `.lead-in`, `.pay`, `.divider` and `.turn` all have theirs.

Note the arithmetic that makes it fit, because it is the opposite of the
statement-led shape's: 72 + 48 for the `.lead-in`, 192 for the `.pay`, 99 for
the divider, and five turn lines at 72 comes to 771 against the 918px band. The
statement-led shape overruns with anything below the payoff only because its
`.claim` has already spent most of the band before the word arrives. "Nothing
goes below the payoff" is a fact about that shape, not about `.pay`.

**Payoff has a second, statement-led shape: `.claim` `.divider` `.lead-in`
`.pay`.** The documented Payoff opens on a `.head`, which suits a slide whose
whole job is to answer a label. Where the payoff word instead ends a sentence
the slide has already been building — build 2 post 1's "One of these is
evidence." — the statement carries the weight and the `.lead-in` is just the
run-up to the word. Two things this shape needs, both learned by overrunning.
The statement takes `.claim`, not `.lead`: at `.lead` that slide measured 1009px
against the 918px band, overset at both ends. And nothing else goes below the
payoff — a `.margin-note` under a 192px word does not fit in any combination.

Annotation classes, usable inside any of them: `.hl` (marker),
`.pen--circle` / `--under` / `--strike` (inline pen marks), and `.sel` (a word
boxed with corner handles, once per deck on the cover).

**Every mark sits on a word.** A brace hung in the right margin was tried and
cut: at the sizes this deck runs, a mark floating outside the text block reads
as debris rather than as annotation.

### The vocabulary is semantic. Read the sentence, then pick

This is the rule the rest of the annotation section hangs off, and it is the one
most easily lost, because every other rule here reads like a recipe and this one
is a judgment.

| The copy is | Mark |
|---|---|
| naming the load-bearing phrase the slide turns on | marker |
| holding one word up to be doubted or examined | circle |
| affirming something, stating a verdict | underline |
| denying something the sentence itself denies | strike |
| naming the object the whole post is about | selection box, once, on the cover |

**A treatment that worked on the last deck is not a default for the next one.**
Build 2 produced this failure twice in one session, both times by copying rather
than reading. A payoff was circled on post 1 only because the kit example
circles its own, and a five-character circle limit was written down as a flat
rule from three inline failures without noticing every one of them shared a
cause. In both cases the fix was to go back to what the words were doing.

Two decks landing on the same combination is fine when the copy earns it; two
decks landing on it because one was built after the other is how a set flattens.
Before a mark goes down, the question is what this sentence is doing — not what
the previous slide did, not what the previous deck did, and not which device was
last suggested in conversation. A suggestion is a candidate to test, not an
instruction to apply everywhere.

**Check the tally when the deck is done.** Count the devices across the finished
set. The marker should lead — it is the workhorse and the design system says so
— but a deck where a second device never appears has stopped reading the copy.
Build 2 post 1 runs 8 markers, 4 circles, 3 underlines, 1 strike, 1 box across
nine slides; post 5 runs 8 markers, 2 circles, 2 strikes, 1 underline, 1 box
across seven. Different shapes, because the copy is different.

**The sharing-a-line limit bites at `.claim` too, and five characters is not a
pass.** Build 3 post 1 circled "again" at the end of a `.claim` line and got the
documented flat ellipse: the stroke ran across "gain" and overshot into the
period, with "means cleaning" hard against it on the left. Five characters holds
at `.turn`; at 78px the same five are wide enough to flatten. The word there was
stating a consequence rather than being doubted, so the fix was the underline
the sentence actually wanted, not a wider loop. Look at the rendered slide
before keeping any inline circle above turn size.

**A circle is limited by glyph width, not character count, and a deck may end
up with none.** The five-character guidance kept failing on words that counted
five: "again" at `.claim`, "2am" at three, "small" at five. What they share is a
wide glyph, an m or a digit, so the loop stretches past a true circle and lands
across the letterforms. Before keeping any inline circle, look at the rendered
slide rather than counting.

Build 3 post 5 ships with no circle at all, and that is the right answer rather
than a gap. Its one candidate was a word the copy had already put in quotation
marks, so the doubt was written into the sentence and a circle said the same
thing twice. Four devices still appear across that deck. The tally note below is
about not letting a *second device* vanish, not about fielding all five.

**A `.pen` takes its own line box, so punctuation beside it can strand.** The
same slide left an opening quotation mark at the end of one line while the
circled word wrapped to the next. Wrap the quotes and their word in `.nb`.

**A circle goes on one word.** Stretched over a phrase it flattens into a wide
ellipse that overshoots the last word and cuts through the first, and it stops
looking drawn. Two of post 7's circles were pulled back to a single word for
this reason. If a phrase needs marking, that is what the marker is for.

**And, set inline in a running line, on a short one — five characters.** The
loop is a fixed 1.24em tall and only ever widens, so length alone flattens it,
and one word is not on its own enough. Build 2's post 1 hit this three times in
one pass: "apologized" at `.lead` was a flat ellipse struck through the middle
of the word, "evidence" at `.turn` and "report" at `.lead` both had the stroke
cutting the last glyph. "guess", "still", "words", "$150" and "$60" all hold.
When an inline word is longer than that, the marker takes it instead.

**This limit is about sharing a line, not about length.** It was first written
here as a flat five-character rule and that was wrong — the kit's own post 1
example circles "nothing." at eight characters and it is one of the best marks
in the set. What actually breaks an inline circle is that the loop has
neighbouring words hard against it on both sides and only 1.24em of height to
work in, so a wide ellipse has nowhere to go and lands across the letterforms.
A word standing alone on its own line has air around it, so the loop can be as
wide as it needs to be and still read as drawn. See the payoff note below.

**On an inverted slide, trailing punctuation goes inside the highlight.** The
padding on `.hl` overhangs the glyphs and the equal negative margin pulls the
next character back onto that overhang — which is the whole point on paper,
where an ink comma on gold reads fine and a detached one reads as a typo. On the
dark ground the following character is `--paper` on gold, a contrast ratio
around 1.4:1, and it washes out. Build 2 posts 1 and 5 both shipped a draft this
way before it was caught. Put the comma or period inside the span; the swipe
simply grows to cover it. On paper slides, leave punctuation outside as normal.

**A marker that wraps at display size reads as two marks.** `.hl` cloning onto
every line box is correct and is why it is exempt from the pen's line-break
rule, but at `.close-lead` or `.display` a wrapped phrase becomes two stacked
full-width gold bars, and on the inverted slide that is the loudest thing in the
deck saying the wrong number. Build 2 post 1 swiped "sorted on description"
across the close and pulled it back to "description". At `.lead` and below,
wrapping is fine — slides 4 and 6 of that deck both do it.

**The selection box stays at one per deck because rarity is what it means.**
This gets questioned every time, because the box is the boldest device in the
kit and appears on one slide in nine. The answer is that it is not the only
once-per-deck mark — the strike is usually the same, and nobody reads that as
underuse. The box says "this is the object the post is about", and a second one
stops identifying anything. Three checks before reaching for another: blue is
probably not actually scarce in the deck (the pen carries it on most slides, and
every page number is blue — what is scarce is *filled* blue, deliberately); the
cover is the feed thumbnail and the box is the heaviest mark on the one slide
that has to stop a scroll alone; and across a multi-deck build, one box per
cover is what makes the set recognisable as a set. Every candidate second
location tried on build 2 post 1 failed for a structural reason, not a taste
one — see the payoff note above, and note that boxing a word in one half of a
mirrored pair breaks the parallel-marks rule against the other half.

**The marker swipe lives once, in `--swipe`.** Both things that paint it — a
highlighted phrase and a `.checks--marked` numeral — read the same custom
property, so they cannot drift apart. Note that its default placement is set
for prose, which has descenders and wants the swipe to overhang the baseline.
Lining figures have neither, so `.checks--marked` raises and grows the swipe;
without that it sits under the numeral as a faint underline rather than behind
it. The same correction is why the inverted slide restates it.

**Zodiak sets exactly one word in the deck** — the payoff on slide 6. The note
underneath it takes the same treatment as the second line on every other
slide, so the second voice speaks once and means something.

**Every deck gets a payoff slide. Go looking for it before writing any HTML.**
This is a build step, not an option, and it is the one thing in this file that
has to happen while the slides are still being mapped to layouts — the notes
below describe how to set a payoff, which is no use to anyone who never asked
whether the deck has one. Build 2 post 5 was built, rendered and handed over
with no Zodiak in it at all, because everything recorded here was reference for
a decision already taken.

Read the copy for the one word the deck lands on. It is usually the last word of
a sentence that closes a slide, and it is often on the close. Three tests: it
has to be **one word**, it has to **end its sentence** so the quiet run-up can
sit above it in `.lead-in`, and it has to be **short enough to set at 192px** —
about nine characters, since post 1's "evidence." already sat at the margin. If
nothing in the copy passes all three, the deck genuinely has no payoff and
Zodiak stays out; say so rather than forcing a word into it.

**Marking the payoff word: the sentence decides, not the precedent.** There is
no house mark for payoffs. Read what the word is doing and take the device that
means it — the same way you would for any other word on any other slide.

| The payoff word is | Mark | Live example |
|---|---|---|
| an affirmation, a verdict being asserted | underline | post 1, "One of these is **evidence.**" |
| a word held up to be doubted or interrogated | circle | post 5, "Check whether your process **knows.**" |
| an answer stated flat, almost as a provocation | circle | the kit example, "What the model decides: **nothing.**" |

Circle it with the **double stroke** — a full loop plus a second sweep at 0.65
opacity. That second stroke is most of why it reads as a hand rather than an
ellipse; every circle that failed in build 2 was a single stroke. Length is not
what limits the *loop* at payoff size, because the word stands alone on its
line: "evidence." at nine characters and "knows." at six both hold.

**The measure limits the word itself, and it is nine characters.** Measured, not
estimated: "evidence." fills the 888px column with about 16px to spare and
"emergency." at ten clips off the right edge. This is what actually decides
whether a deck can have a payoff, so test the candidate before building the
slide around it. There is one `.pay` size, 192px, and no smaller step — if a
deck's landing word is genuinely longer and worth having, that is a new size in
the scale (a multiple of 24 for its leading, plus its `.slide--invert` colours),
not something to solve on the slide.

**On the dark ground the pen goes gold**, so an inverted payoff is a gold circle
or a gold underline. The kit's post 1 example is the reference for this: its
payoff and its inverted slide are the same slide, which puts both of the deck's
spikes in one frame. Worth reaching for when a deck's landing word sits on the
slide the argument turns on. Neither build 2 deck could take it — post 1's
inverted close lands on "emergency." at ten characters, and post 5's on
"optimistic." at eleven, and both overrun.

The other two marks are not available here. The marker sits wrong: `--swipe` is
placed for prose x-height, so at 192px it lands as a gold shelf under the word
rather than a mark on it, and correcting it would need a `.pay.hl` rule
restating the swipe the way `.checks--marked li b` does. The selection box is
worse than wrong, it is silently broken: `.pay` declares `color: var(--ink)` and
sits later in the stylesheet than `.sel`, so a boxed payoff renders ink on blue
instead of paper on blue and goes muddy.

**The underline's overhang is outside the box model.** `.pen--under` hangs
0.18em below its span and that space is not in the layout, so the centred block
does not account for it. On a payoff slide it put the stroke nine pixels off the
footer rule while every measurement said the block fitted. Look at the rendered
slide; the numbers will not tell you.

**Measure the fit before looking, with `scripts/check-fit.py`.** It renders each
deck headless and reports, per slide, the clearance between the content block
and the eyebrow above it and the footer or byline below it. Two things it
settled that the eye kept arguing about.

The band is not the limit. Content taller than the 918px band overflows the
centred block symmetrically, and the 192px between the band edge and the footer
absorbs a good deal of it, so a slide can measure "overset" against the band and
still be correct on the page. What matters is the clearance to the furniture:
below about 24px the last line starts crowding the footer rule.

And it finds what a contact sheet hides. Build 3 post 5 had three slides
genuinely overset before the first render, all fixed in one pass instead of three
rounds of look-and-nudge. Run it after any type or layout change; keep looking at
the slides afterwards, because it says nothing about where a mark landed.

**Content centers in a bounded band** between the eyebrow and the footer.
Slide copy runs from 8 words to 24, so a fixed top anchor strands short
slides in the upper third with a dead page underneath.

## One deck, no variants

There was briefly a `theme-flip` theme (ink and pen swapped) and a `loud`
theme (bigger type, tighter margins, heavier strokes) layered over a quieter
base. The loud settings won and are now the template's own values. Both
variant files are deleted.

Do not reintroduce a theme layer for a single consumer. Every change then has
to be made twice, and the base it overrides has no other reader. If a future
post needs a different treatment, add a named layout, not a theme.

## The baseline grid

The ruled lines are drawn every 72px. The **baseline unit is 24px** — every
third unit is a drawn rule.

- **Every leading is set in px and is a multiple of 24.** Display 144, lead
  120, turn 72, checks 72, detail and note 48, payoff 192.
- **Every vertical margin and padding is a multiple of 24.** No exceptions,
  including the eyebrow offset, the footer band, and the divider.
- `.turn` and `.checks` sit exactly on a drawn rule on every line, because
  their leading is 72. Display and detail land on the sub-grid and coincide
  with a drawn rule periodically, which is what a baseline grid normally
  looks like.
- **The content block is vertically centred, so a render-time script snaps
  it.** It measures each slide's first baseline with a zero-size inline-block
  probe and translates the block onto the nearest unit. The shift is never
  more than 12px, so centring survives. The script lives at the foot of each
  post file and runs before Chrome prints.

Changing a type size means checking its leading is still a whole number of
units. That is the only maintenance cost of the grid, and it is the thing
that makes the page read as constructed rather than decorated.

## The inverted slide

**One inverted slide per deck**, on the page the argument turns on. In post 1
that is slide 6, the payoff; in post 4 it is slide 5, the question the whole
post hands to the reader; in post 7 it is slide 9, the thesis. Used more often
it stops being a spike and becomes a pattern, which reads quieter, not louder.

Post 13 is the one deck that inverts its **close**, and the reason is worth
keeping. That slide was to have been a screenshot of a real approval email, and
when the artifact was dropped the proof had to be stated in type instead. Left
alone it would have been another statement slide in a deck of statement slides,
so the inversion carries the weight the photograph would have. Invert a close
only when it is doing that job, not because it is last.

**A layout is not finished until its inverted colours exist.** Inverting post
13's close put a `.byline` on the dark ground for the first time and it vanished,
because `.byline` is ink and nothing had ever needed it otherwise. `.claim`,
`.group`, `.lead-in`, `.lead-out` and `.detail` were unhandled for the same
reason. Add a layout, add its `.slide--invert` line in the same pass.

**`.fig` was missing from that set until build 2 post 6 needed it.** Nothing had
ever put a figure on the dark ground, so `.fig` kept its ink colour and would
have rendered navy on navy — invisible, with no error and nothing in the HTML to
suggest a cause. It is declared now. That deck also found the best use of the
inverted ground so far: a four-letter figure at 208px, standing alone, is close
to a true circle rather than a flat ellipse, so the gold loop lands on it
properly. If a deck's argument turns on a number, that combination is the
loudest single frame this template can make.

**`.sel` is still missing from that set, and currently works by luck.** It was
rendered on an inverted close during build 2 post 1 and read fine, but only
because `--sel` and `--paper` happen to hold on the navy ground; nothing
declares it. Anyone who retunes `--sel` breaks the inverted case with no warning
and no reason to look. It is unfixed because that deck kept the box on the cover
and nothing shipped depending on it. Declare `.slide--invert .sel` explicitly —
same values are fine — before any deck puts a box on the dark slide.

The cover was briefly inverted too, to establish the dark ground before slide
6 used it. That was reverted: a light cover keeps the dark slide as the single
loudest frame in the deck. If slide 6 ever starts reading as a mistake rather
than as the payoff, the fix is to make slides 5 and 6 an obviously matched
pair, not to invert the cover again.

On an inverted slide the colour rule still holds: every word is one value
(`--paper`), and only annotations carry colour. Highlighted words go dark so
they stay legible on the gold swipe.

**The swipe also has to grow there, and flipping the colour alone is not
enough.** `.hl` is sized to overhang a word rather than to enclose it, so on
paper the uncovered ascenders are still ink on cream and read fine. On the
inverted ground they are dark ink on dark navy and disappear — post 4's slide 5
lost half of "cheap part" that way. The stylesheet raises and grows the swipe
on `.slide--invert` so it clears the cap height. Check any highlight that lands
on an inverted slide.

**And cap height is not the top of the glyph.** The correction was first set to
start the swipe at 0.20em, measured against a phrase with no dotted letter in
it. The tittle of an i or a j sits above cap height, so it fell just outside the
gold: build 3 post 3's "nothing is watching." lost all three dots and read
"nothıng ıs watchıng." on the deck's single loudest frame, with no error and
nothing in the HTML to point at. The swipe now starts at 0.08em and is grown by
the same 0.12em, so its bottom edge is unchanged at 1.44em and only the headroom
moved. A highlight whose words happen to have no ascender or tittle will not
show this, which is why it survived a whole build.

## Consistency rules

Learned from an audit that found eleven inconsistencies in the first build.
Each of these exists because something looked like a mistake.

1. **Three rule weights, declared, and nothing uses a number outside them.**
   `--w-hair` separates, `--w-line` outlines, `--w-mark` is furniture the eye
   reads as a deliberate stroke.
2. **Both furniture marks are gold.** The eyebrow rule and the byline rule
   are the same 38px stroke and must stay the same color.
3. **One treatment for "the line after the statement."** Always `.turn`,
   always behind a `.divider`. There is no second, quieter variant — an
   earlier pass set one slide's closer in 400-weight grey and it buried a
   load-bearing line.
4. **Parallel copy gets parallel marks.** Mirrored sentences take the same
   device with different hand-drawn paths, never different devices.
5. **Every slide carries at least one mark.** In a deck whose identity is
   the annotation layer, a bare page reads as an omission.
6. **`.hl` cancels its own padding with an equal negative margin.** Without
   it the character after a highlight detaches and reads as a typo.
7. **No flex containers around annotated text.** A flex parent turns an
   inline `.pen` span into its own flex item and tears the sentence apart.
   `.checks` positions its numeral instead.

## The film grain, and why it is a tile

A 128x128 noise tile at 5% opacity on every slide, so a flat PDF reads as
printed rather than screenshotted. Two constraints, both learned the hard
way, and both worth keeping.

**It must never be an `feTurbulence` filter.** A filter has to be evaluated
at output resolution, so Chrome bakes a full-page bitmap into every slide.
That took the PDF from 132 KB to **24 MB** for visually identical output —
32 embedded images instead of 1. Shrinking the filter's tile does nothing;
only baking it to a real image does.

**The tile must be high-passed.** Generate noise, blur it lightly so it
clumps like fractal noise rather than looking sandy, then subtract a heavily
blurred copy so the tile carries no large-scale light and dark regions. Skip
that step and the tile's own variation repeats across the page and the grid
becomes plainly visible. All blurs wrap at the edges so there is no seam.

Nothing else in the deck is raster. Type is vector with embedded font
subsets, and every mark, rule and box is a vector shape, so file size and
visual quality are independent here.

## Standing rules

- **Nothing bleeds across the footer.** An earlier pass let a graphic run
  over the page number and it read as a mistake rather than a decision.
  Overlap is allowed and wanted, but only where a person would have made it:
  a marker over a word, a circle around a phrase.
- No progress dots, no swipe prompt, no logo, no icon sets, no stock or AI
  imagery.
- The document title typed on upload is displayed in the feed. Use the cover
  line, not a filename.
