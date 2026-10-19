"""Check the exported carousel against its Markdown copy; visual QA is separate."""
import re
from pathlib import Path
from pypdf import PdfReader
import pdfplumber

ROOT = Path(__file__).resolve().parents[2]
source = (ROOT / 'docs/build-4-content-strategy/technical-retrospective-carousel.md').read_text(encoding='utf-8')
fields = re.findall(r'### Slide (\d+)\n\n\*\*Title:\*\* ([^\n]+)\n\n\*\*Body:\*\* ([^\n]+)\n\n\*\*Footer:\*\* ([^\n]+)', source)
pdf = ROOT / 'carousel-kit/out/technical-retrospective-make-ready.pdf'
assert pdf.exists(), f"PDF not found at {pdf}"
reader = PdfReader(pdf)
assert len(reader.pages) == len(fields) == 11, f"Expected 11 pages, got {len(reader.pages)} in PDF and {len(fields)} in Markdown"

compact = lambda s: re.sub(r'[\s\u00b7\ufffd]+', '', s)
positioned = pdfplumber.open(pdf)
fonts = set()
images = set()
seen = set()

def inspect_resources(resources):
    resources = resources.get_object()
    for obj in resources.get('/Font', {}).values():
        fonts.add(str(obj.get_object().get('/BaseFont', '')))
    for obj in resources.get('/XObject', {}).values():
        key = (obj.idnum, obj.generation)
        if key in seen:
            continue
        seen.add(key)
        item = obj.get_object()
        if item.get('/Subtype') == '/Image':
            images.add(key)
        if item.get('/Resources'):
            inspect_resources(item['/Resources'])

for page, (number, title, body, footer) in zip(reader.pages, fields):
    text = positioned.pages[int(number) - 1].extract_text()
    for label, expected in [('title', title), ('body', body), ('footer', footer)]:
        assert compact(expected) in compact(text), f'Slide {number}: {label} copy mismatch (expected "{expected}")'
    assert abs(float(page.mediabox.width) - 810) < 1, f"Page {number} width unexpected: {page.mediabox.width}"
    assert abs(float(page.mediabox.height) - 1012.5) < 1, f"Page {number} height unexpected: {page.mediabox.height}"
    assert not re.search(r'(D:[/\\]|C:[/\\]|localhost|__AIRTABLE|Production notes|Evidence and copy checks)', text), f"Slide {number} contains internal strings"
    inspect_resources(page['/Resources'])

assert len(fonts) >= 6, f"Too few font subsets: {fonts}"
image_count = len(re.findall(rb'/Subtype\s*/Image\b', pdf.read_bytes()))
assert image_count == 1, f"Expected 1 image object (the grain tile), got {image_count}"
print(f'PASS: {len(fields)} pages; title/body/footer wording preserved on every page; expected dimensions; no internal notes/paths; {len(fonts)} font subsets; one shared grain image; {pdf.stat().st_size:,} bytes.')
