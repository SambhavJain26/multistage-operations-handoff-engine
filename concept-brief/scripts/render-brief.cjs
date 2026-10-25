/**
 * Render and validate the Make-Ready Sequencing Solution Brief.
 * 
 * Usage:
 *   node render-brief.cjs                                    # Render reusable template PDF
 *   node render-brief.cjs --data ../fixtures/prospect-data.qa.json  # Render prospect PDF
 *   node render-brief.cjs --data <file.json> --output <dest.pdf>    # Render with custom destination
 */

const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");
const { pathToFileURL } = require("node:url");

const root = path.resolve(__dirname, "../..");
const templatePdf = path.join(root, "output/pdf/make-ready-solution-brief-template.pdf");
const protectedPdfs = [
  templatePdf,
  path.join(root, "output/pdf/make-ready-solution-brief-original.pdf")
];

function parseOptions(argv) {
  const options = {};
  for (let i = 0; i < argv.length; i++) {
    const flag = argv[i];
    if (flag !== "--data" && flag !== "--output") throw new Error(`Unknown option: ${flag}`);
    if (!argv[i + 1] || argv[i + 1].startsWith("--")) throw new Error(`${flag} requires a valid path argument`);
    options[flag.slice(2)] = argv[++i];
  }
  if (options.output && !options.data) throw new Error("--output requires --data");
  return options;
}

function loadProspect(file) {
  if (!file) return null;
  const filePath = path.resolve(file);
  if (!fs.existsSync(filePath)) throw new Error(`Prospect data file not found: ${filePath}`);

  const data = JSON.parse(fs.readFileSync(filePath, "utf8"));
  const filled = (value, field) => {
    if (typeof value !== "string" || !value.trim() || /\[[^\]]+\]/.test(value)) {
      throw new Error(`Fill ${field} with verified prospect information (no bracketed placeholders)`);
    }
    return value.trim();
  };

  if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(data.slug || "") || data.slug === "replace-with-prospect-slug") {
    throw new Error("Set slug to a short lowercase alphanumeric hyphenated prospect identifier");
  }

  data.company = filled(data.company, "company");
  data.decisionMaker = filled(data.decisionMaker, "decisionMaker");

  if (!data.research || !Array.isArray(data.research.reviewed) || data.research.reviewed.length < 1 || data.research.reviewed.length > 3) {
    throw new Error("research.reviewed needs one to three short source labels");
  }
  data.research.reviewed = data.research.reviewed.map((item, i) => filled(item, `research.reviewed[${i}]`));
  data.research.note = filled(data.research.note, "research.note");
  if (data.research.note.length > 300) {
    throw new Error(`Keep research.note under 300 characters for optimal layout (currently ${data.research.note.length})`);
  }

  // Validate internal evidence if present (never rendered into PDF)
  if (data.research.evidence && !Array.isArray(data.research.evidence)) {
    throw new Error("research.evidence must be an array of { fact, source } objects");
  }

  for (const group of ["systems", "routes"]) {
    data[group] ||= {};
    if (typeof data[group] !== "object" || Array.isArray(data[group])) throw new Error(`${group} must be an object`);
    for (const [name, value] of Object.entries(data[group])) {
      if (typeof value !== "string") throw new Error(`${group}.${name} must be text`);
      data[group][name] = value.trim();
    }
  }

  return data;
}

const options = parseOptions(process.argv.slice(2));
const prospect = loadProspect(options.data);
const output = prospect
  ? path.resolve(options.output || path.join(root, "output/pdf", `${prospect.slug}-make-ready-solution-brief.pdf`))
  : templatePdf;

// Safeguard against overwriting protected / reusable template PDFs
if (prospect) {
  if (protectedPdfs.some((file) => path.normalize(file).toLowerCase() === path.normalize(output).toLowerCase())) {
    throw new Error(`Prospect export cannot overwrite protected PDF: ${output}`);
  }
}

let playwright;
try {
  playwright = require("playwright");
} catch {
  playwright = require(path.join(os.homedir(), ".cache/playwright-runtimes/dependencies/node/node_modules/playwright"));
}

(async () => {
  const browser = await playwright.chromium.launch({
    channel: process.env.BRIEF_BROWSER || "msedge",
    headless: true
  });

  try {
    const page = await browser.newPage({ viewport: { width: 1000, height: 1000 }, deviceScaleFactor: 1 });
    const errors = [];
    page.on("pageerror", (error) => errors.push(error.message));

    const htmlPath = path.join(root, "concept-brief/make-ready-solution-brief.html");
    await page.goto(pathToFileURL(htmlPath).href);

    if (prospect) {
      await page.evaluate((data) => {
        const values = {
          company: data.company,
          decisionMaker: data.decisionMaker,
          "research.reviewed": data.research.reviewed.join("\n"),
          "research.note": data.research.note,
          "systems.hosting": data.systems.hosting,
          "systems.pms": data.systems.pms,
          "systems.inspectionTool": data.systems.inspectionTool,
          "systems.managerChannel": data.systems.managerChannel,
          "systems.vendorChannel": data.systems.vendorChannel,
          "systems.reportingTool": data.systems.reportingTool,
          "routes.intake": data.routes.intake,
          "routes.pms": data.routes.pms,
          "routes.inspection": data.routes.inspection,
          "routes.manager": data.routes.manager,
          "routes.vendor": data.routes.vendor,
          "routes.reporting": data.routes.reporting
        };

        for (const [field, value] of Object.entries(values)) {
          if (!value) continue;
          const targets = document.querySelectorAll(`[data-prospect="${field}"]`);
          if (!targets.length) throw new Error(`No document field for ${field}`);
          for (const target of targets) {
            target.textContent = value; // Safe text replacement
          }
        }
        document.title = `${data.company} | Make-Ready Sequencing Solution Brief`;
      }, prospect);
    }

    await page.evaluate(() => document.fonts.ready);
    const link = await page.locator(".cta a").getAttribute("href");

    // Geometric layout, overflow, and alignment verification
    const checks = await page.evaluate(() => {
      const pages = [...document.querySelectorAll(".page")];
      return pages.map((paper, idx) => {
        const pageRect = paper.getBoundingClientRect();
        const footer = paper.querySelector(".page-footer").getBoundingClientRect();

        // 1. Escaped elements outside page boundaries or overflowing into footer
        const escaped = [...paper.querySelectorAll("h1, h2, h3, p, .comparison-card, .stage, .external-card, .stack-card, .routes, .cta, .pilot-measures, .controls")]
          .filter((element) => {
            const box = element.getBoundingClientRect();
            return box.left < pageRect.left - 0.5 || box.right > pageRect.right + 0.5 || box.bottom > footer.top - 1;
          })
          .map((element) => element.className || element.tagName);

        // 2. Clipped elements overflowing their immediate card parents
        const clipped = [...paper.querySelectorAll(".comparison-card, .stage, .external-card, .stack-card, .research-copy, .daily .shell-inner, .authority .shell-inner, .controls, .cta .shell-inner, .measure-pill")]
          .filter((parent) => {
            const box = parent.getBoundingClientRect();
            return [...parent.querySelectorAll("h2, h3, p, strong, .actor, a, .rule-note")].some((child) => {
              const b = child.getBoundingClientRect();
              return b.right > box.right + 1 || b.bottom > box.bottom + 1;
            });
          })
          .map((element) => element.className);

        // 3. Elements with tight inner text spacing (< 8px)
        const tight = [...paper.querySelectorAll(".research-sources, .research-copy, .comparison-card, .external-card, .stack-card, .daily .shell-inner, .authority .shell-inner, .controls, .cta .shell-inner")]
          .map((parent) => {
            const box = parent.getBoundingClientRect();
            const text = [...parent.querySelectorAll("h2, h3, p, .small-label, strong")];
            if (!text.length) return null;
            const bottom = Math.min(...text.map((child) => box.bottom - child.getBoundingClientRect().bottom));
            const right = Math.min(...text.map((child) => box.right - child.getBoundingClientRect().right));
            return { component: parent.className, bottom: +bottom.toFixed(1), right: +right.toFixed(1) };
          })
          .filter((entry) => entry && (entry.bottom < 8 || entry.right < 8));

        return {
          pageNumber: idx + 1,
          width: pageRect.width,
          height: pageRect.height,
          escaped,
          clipped,
          tight
        };
      });
    });

    const slug = prospect?.slug || "template";
    const destScreenshots = path.join(root, "tmp/brief-qa", slug);
    fs.mkdirSync(destScreenshots, { recursive: true });

    for (let i = 0; i < 4; i++) {
      await page.locator(".page").nth(i).screenshot({
        path: path.join(destScreenshots, `page-${i + 1}.png`)
      });
    }

    if (errors.length) {
      throw new Error(`Page console/script errors: ${errors.join(", ")}`);
    }

    if (link !== "https://cal.com/sambhav-builds/pm-automation-audit") {
      throw new Error(`CTA link mismatch: ${link}`);
    }

    if (checks.length !== 4) {
      throw new Error(`Expected exactly 4 pages, found ${checks.length}`);
    }

    const failedChecks = checks.filter(
      (c) => c.width !== 864 || c.height !== 864 || c.escaped.length || c.clipped.length || c.tight.length
    );

    if (failedChecks.length > 0) {
      throw new Error(`Layout geometry validation failed: ${JSON.stringify(failedChecks, null, 2)}`);
    }

    fs.mkdirSync(path.dirname(output), { recursive: true });
    await page.emulateMedia({ media: "print" });
    await page.pdf({
      path: output,
      preferCSSPageSize: true,
      printBackground: true,
      displayHeaderFooter: false,
      tagged: true
    });

    console.log(JSON.stringify({
      status: "SUCCESS",
      slug,
      checks,
      ctaLink: link,
      screenshotsDir: destScreenshots,
      outputPdf: output
    }, null, 2));

  } finally {
    await browser.close();
  }
})().catch((error) => {
  console.error("Render failed:", error.message || error);
  process.exitCode = 1;
});
