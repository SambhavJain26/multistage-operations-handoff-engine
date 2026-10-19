// Public prose comes from Markdown; diagram labels explain the same build.
const fs = require('fs'), path = require('path');
const root = path.resolve(__dirname, '../..'), kit = path.join(root, 'carousel-kit');
const source = fs.readFileSync(path.join(root, 'docs/build-4-content-strategy/technical-retrospective-carousel.md'), 'utf8').replaceAll('\r\n', '\n');
const esc = s => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
const paths = {
  circle: '<svg viewBox="0 0 300 100" preserveAspectRatio="none"><path d="M23,52 C20,20 88,6 160,7 C238,8 286,25 283,53 C280,81 210,95 138,94 C66,93 20,79 17,49 C15,32 32,19 58,11"/><path d="M43,13 C115,1 215,11 269,31 C293,40 296,59 273,73" opacity=".65"/></svg>',
  under: '<svg viewBox="0 0 300 20" preserveAspectRatio="none"><path d="M4,12 C62,3 148,4 214,9 C250,12 274,12 296,7"/><path d="M12,18 C72,10 150,11 222,15" opacity=".55"/></svg>',
  strike: '<svg viewBox="0 0 300 12" preserveAspectRatio="none"><path d="M2,7 C74,3 168,10 298,4"/></svg>',
};
function a(text, type, color = 'blue') {
  const s = esc(text);
  if (type === 'hl') return `<span class="hl${color === 'blue' ? ' hl--blue' : ''}">${s}</span>`;
  if (type === 'sel') return `<span class="sel${color === 'gold' ? ' sel--gold' : ''}">${s}<i></i><i></i><i></i><i></i></span>`;
  return `<span class="pen pen--${type} pen--${color}">${s}${paths[type]}</span>`;
}
const chain = (nodes) => `<div class="v-chain v-chain--${nodes.length}">${nodes.map((n, i) => `${i ? '<div class="v-arrow">→</div>' : ''}<div class="v-node">${n}</div>`).join('')}</div>`;
const lane = (label, content) => `<div class="v-lane"><div class="v-label">${label}</div>${content}</div>`;
const table = (headers, rows, cls = '') => `<table class="v-table ${cls}"><thead><tr>${headers.map(x => `<th>${x}</th>`).join('')}</tr></thead><tbody>${rows.map(row => `<tr>${row.map(x => `<td>${x}</td>`).join('')}</tr>`).join('')}</tbody></table>`;
const steps = (rows) => `<ol class="v-steps">${rows.map((r, i) => `<li><b>${String(i + 1).padStart(2, '0')}</b><h3>${r[0]}</h3><p>${r[1]}</p></li>`).join('')}</ol>`;

const diagrams = {
  2: steps([['Trades depend on order', 'Repairs, painting, flooring, and cleaning have fixed order.'], [a('One early contractor', 'hl', 'gold'), 'Clean before repairs or paint, and the unit must be cleaned again.']]),
  3: lane('When a trade finishes', chain(['Contractor text', 'Match unit', a('Check trade order', 'hl', 'gold')])) + lane('Before next dispatch', chain(['Draft handoff', 'Manager review', a('Send email or text', 'hl', 'blue')])) + '<div class="v-rail">The next contractor is only notified after a manager approves.</div>',
  4: `<div class="v-columns"><div class="v-column"><h3>AI assists</h3><p>Parse messy texts</p><p>Identify unit hint</p><p>Draft next notice</p></div><div class="v-column"><h3>Manager decides</h3><p>Resolve ambiguity</p><p>Pick email or text</p><p>${a('Approve each dispatch', 'sel', 'blue')}</p></div></div>`,
  5: steps([['Fixed dependencies', 'Repairs before paint. Paint before flooring. Cleaning last.'], [a('Hard sequence guard', 'hl', 'blue'), 'If a cleaner reports done while repairs remain open, the system halts.'], ['Clear reason given', 'The manager sees exactly which prior trade is still pending.']]),
  6: lane('The gap', chain(['Contractor replies', 'Header in metadata', a('Reply dropped', 'strike', 'gold')])) + `<p class="v-gap">${a('Treated as outgoing copy', 'under', 'gold')}</p>` + lane('The fix', chain(['Read metadata', a('Extract thread ID', 'sel', 'blue'), 'Link to unit'])) + '<p class="v-quiet">Threaded replies now route to the active turnover unit.</p>',
  7: lane('The bug', chain(['Batch 1 mapped', 'Batch 2 unmapped', a('Broken links', 'strike', 'blue')])) + lane('The fix', chain(['Batch responses', a('Pair each by index', 'sel', 'gold'), 'All records linked'])) + '<p class="v-quiet">Every batch response is now matched to its input items.</p>',
  8: table(['What comes in', 'What happens'], [['Two units match text', 'Manager chooses unit'], ['Bare message with no unit', a('Escalate to manager', 'hl', 'gold')], ['Out-of-order trade report', 'Block advance with reason'], ['Unconfigured channel', a('Alert manager, do not send', 'under', 'blue')]], 'v-results'),
  9: `<div class="v-route"><p>The informal text</p><p class="v-route-arrow">↓</p><p>The ${a('ambiguous unit', 'circle', 'gold')}</p><p class="v-route-arrow">↓</p><p>The ${a('out-of-order report', 'under', 'blue')}</p><p class="v-route-arrow">↓</p><p>The double-tapped button</p></div>`,
  10: table(['I checked', 'Recorded behavior'], [['Informal trade slang', 'Understood unit and intent'], ['Ambiguous property name', a('Escalated for manager choice', 'hl', 'gold')], ['Cleaning before paint', 'Advance blocked with reason'], ['Approve tapped twice', a('No duplicate dispatch sent', 'under', 'blue')]], 'v-results'),
  11: steps([['Standardized photo intake', 'Collect photo evidence before approving expensive trades.'], ['Two-way arrival tracking', 'Confirm contractor arrival windows before alerting the next trade.'], [a('Accounting system write-back', 'hl', 'blue'), 'Close work orders and post invoices automatically once approved.']]),
};

const titleMarks = {
  1: [],
  2: ['paying twice', 'under', 'blue'],
  4: ['dispatches', 'hl', 'gold'],
  5: ['in code', 'sel', 'blue'],
  6: ['silently ignored', 'under', 'gold'],
  7: ['lost links', 'strike', 'blue'],
  8: ['person', 'circle', 'blue'],
  9: ['seams', 'circle', 'gold'],
  10: ['awkward cases', 'under', 'blue'],
  11: ['next', 'circle', 'gold']
};

const slides = [...source.matchAll(/### Slide (\d+)\n\n\*\*Title:\*\* ([^\n]+)\n\n\*\*Body:\*\* ([^\n]+)\n\n\*\*Footer:\*\* ([^\n]+)/g)];
if (slides.length !== 11) throw Error('Expected eleven slide fields, got ' + slides.length);

const shells = slides.map(m => {
  const n = +m[1], title = m[2], body = m[3], footer = m[4];
  let h = esc(title);
  if (titleMarks[n]?.length) {
    const [word, type, color] = titleMarks[n];
    if (!h.includes(word)) throw Error(`Slide ${n}: Missing title mark "${word}" in "${h}"`);
    h = h.replace(word, a(word, type, color));
  }
  let content;
  if (n === 1) {
    h = 'Turnover<br>coordination that<br>protects the<br><span class="pay pen pen--under pen--gold">sequence' + paths.under + '</span>';
    content = `<h1 class="display v-cover">${h}</h1><p class="tech-copy">${esc(body)}</p>`;
  } else {
    if (n === 7) h = h.replace(' after', '<br>after');
    const heading = `<h2 class="tech-title">${h}</h2>`, copy = `<p class="tech-copy">${esc(body)}</p>`, visual = `<div class="v-visual">${diagrams[n]}</div>`;
    content = heading + visual + copy;
  }
  return `<section class="slide technical technical--visual${n === 9 ? ' slide--invert' : ''}" data-slide="${n}"><div class="eyebrow"><span>BUILD NOTES · TURNOVER COORDINATION</span></div><div class="body">${content}</div><div class="footer"><span>${esc(footer)}</span><b>${String(n).padStart(2, '0')}</b></div></section>`;
});

const snap = `
<script>
(function () {
  var UNIT = 24, PHASE = 71.5;
  document.querySelectorAll('.slide').forEach(function (slide) {
    var body = slide.querySelector('.body');
    if (!body) { return; }
    var host = body.querySelector('.display, .lead, .head, .group, .lead-in, .claim, .fig, .close-lead, .pay, .checks li');
    if (!host) { host = body.firstElementChild; }
    if (!host) { return; }

    var probe = document.createElement('span');
    probe.style.cssText = 'display:inline-block;width:0;height:0;overflow:hidden';
    host.insertBefore(probe, host.firstChild);
    var baseline = probe.getBoundingClientRect().bottom - slide.getBoundingClientRect().top;
    probe.remove();

    var delta = Math.round((baseline - PHASE) / UNIT) * UNIT + PHASE - baseline;
    body.style.transform = 'translateY(' + delta.toFixed(2) + 'px)';
  });
})();
</script>`;

const html = `<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Turnover coordination that protects the sequence</title><link rel="preconnect" href="https://api.fontshare.com"><link rel="preconnect" href="https://cdn.fontshare.com" crossorigin><link href="https://api.fontshare.com/v2/css?f[]=switzer@400,500,600,700,800,900&display=swap" rel="stylesheet"><link href="https://api.fontshare.com/v2/css?f[]=zodiak@700,701,800,801&display=swap" rel="stylesheet"><link href="carousel-template.css" rel="stylesheet"></head><body>${shells.join('\n')}${snap}</body></html>`;
const out = path.join(kit, 'technical-retrospective-make-ready.html');
fs.writeFileSync(out, html);
console.log('Wrote ' + out);
