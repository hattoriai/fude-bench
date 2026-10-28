// Loads each library's pages in a browser and measures them: when the
// charts are drawn, how long the main thread was blocked, the memory and
// DOM they take, and what an update of the data costs (time and bytes over
// the LiveView socket). The server (`mix bench` or `mix bench.serve`) must
// be running.
//
//   node run.mjs [--runs 7] [--browsers chromium,firefox,webkit] [--libs fude,contex]
//                [--pages scatter,lines,bars,dashboard] [--cpu 4] [--out ../results/browser.json]
//                [--base http://127.0.0.1:4200] [--screenshots ../results/screenshots]
//
// Each figure is the median of the runs, each run in a new browser context.

import { writeFileSync, mkdirSync } from "node:fs";
import { createRequire } from "node:module";

// By require, so that a Playwright installed globally (NODE_PATH) works too.
const playwright = createRequire(import.meta.url)("playwright");

const args = Object.fromEntries(
  process.argv.slice(2).reduce((pairs, arg, i, all) => (arg.startsWith("--") ? [...pairs, [arg.slice(2), all[i + 1]]] : pairs), []),
);
const BASE = args.base ?? "http://127.0.0.1:4200";
const RUNS = Number(args.runs ?? 7);
const UPDATES = 3;
const CPU = Number(args.cpu ?? 1);
const BROWSERS = (args.browsers ?? "chromium").split(",");
const LIBS = (args.libs ?? "fude,vega_lite,contex,live_charts").split(",");
const PAGES = (args.pages ?? "scatter,lines,bars,dashboard").split(",");
const SERVER_DRAWN = new Set(["contex"]);
const SHOTS = args.screenshots ?? "../results/screenshots";

const median = (values) => {
  const known = values.filter((v) => v !== null && v !== undefined);
  if (!known.length) return null;
  const sorted = [...known].sort((a, b) => a - b);
  return sorted[Math.floor(sorted.length / 2)];
};

const url = (lib, page) => (page === "dashboard" ? `${BASE}/dashboard/${lib}` : `${BASE}/chart/${lib}/${page}`);

async function measure(browser, browserName, lib, page, run) {
  const context = await browser.newContext({ viewport: { width: 1100, height: 900 }, deviceScaleFactor: 1 });
  const tab = await context.newPage();
  const chromium = browserName === "chromium";
  const cdp = chromium ? await context.newCDPSession(tab) : null;
  if (cdp) await cdp.send("Performance.enable");
  if (cdp && CPU > 1) await cdp.send("Emulation.setCPUThrottlingRate", { rate: CPU });

  await tab.addInitScript(() => {
    window.__blocking = 0;
    try {
      new PerformanceObserver((list) => {
        for (const entry of list.getEntries()) window.__blocking += Math.max(0, entry.duration - 50);
      }).observe({ type: "longtask", buffered: true });
    } catch {
      window.__blocking = null;
    }
  });

  let received = 0;
  tab.on("websocket", (socket) => {
    if (!socket.url().includes("/live/websocket")) return;
    socket.on("framereceived", (frame) => (received += Buffer.byteLength(frame.payload)));
  });

  const response = await tab.goto(url(lib, page));
  const htmlBytes = (await response.body()).length;
  const expected = page === "dashboard" ? 12 : 1;
  const serverDrawn = SERVER_DRAWN.has(lib);

  await tab.waitForFunction(
    ([n, server]) => (server ? window.__bench.connected !== null : window.__bench.drawn.length >= n),
    [expected, serverDrawn],
    { timeout: 60_000 },
  );
  await tab.waitForTimeout(300);

  const load = await tab.evaluate(([server]) => {
    const fcp = performance.getEntriesByName("first-contentful-paint")[0]?.startTime ?? null;
    const drawn = server ? fcp : Math.max(...window.__bench.drawn.map((d) => d.t));
    const scripts = performance
      .getEntriesByType("resource")
      .filter((r) => r.name.includes("/libs/"))
      .reduce((sum, r) => sum + (r.encodedBodySize || 0), 0);
    return { fcp, drawn, connected: window.__bench.connected, blocking: window.__blocking, libBytes: scripts, nodes: document.getElementsByTagName("*").length };
  }, [serverDrawn]);
  load.joinBytes = received;
  load.htmlBytes = htmlBytes;

  if (cdp) {
    await cdp.send("HeapProfiler.collectGarbage");
    const { metrics } = await cdp.send("Performance.getMetrics");
    load.heapMB = metrics.find((m) => m.name === "JSHeapUsedSize").value / 1048576;
  } else load.heapMB = null;

  if (run === 0 && browserName === "chromium") {
    mkdirSync(SHOTS, { recursive: true });
    await tab.screenshot({ path: `${SHOTS}/${lib}-${page}.png`, fullPage: true });
  }

  // Updates: the button gives every chart new data; the time is from the
  // click to the last chart drawn again.
  const updates = [];
  const updateBytes = [];
  for (let u = 0; u < UPDATES; u++) {
    received = 0;
    const before = await tab.evaluate(() => {
      window.__bench.updated = [];
      window.__bench.t0 = performance.now();
      document.getElementById("update").click();
      return window.__bench.t0;
    });
    await tab.waitForFunction((n) => window.__bench.updated.length >= n, expected, { timeout: 60_000 });
    const after = await tab.evaluate(() => Math.max(...window.__bench.updated.map((d) => d.t)));
    await tab.waitForTimeout(200);
    updates.push(after - before);
    updateBytes.push(received);
  }
  load.updateMs = median(updates);
  load.updateBytes = median(updateBytes);
  load.nodesAfterUpdates = await tab.evaluate(() => document.getElementsByTagName("*").length);

  await context.close();
  return load;
}

const results = { base: BASE, runs: RUNS, cpu: CPU, date: new Date().toISOString(), rows: [] };

for (const browserName of BROWSERS) {
  const browser = await playwright[browserName].launch();
  results[`${browserName}Version`] = browser.version();
  for (const page of PAGES) {
    for (const lib of LIBS) {
      const runs = [];
      for (let run = 0; run < RUNS; run++) runs.push(await measure(browser, browserName, lib, page, run));
      const row = { browser: browserName, page, lib };
      for (const key of Object.keys(runs[0])) row[key] = median(runs.map((r) => r[key]));
      results.rows.push(row);
      console.log(
        `${browserName} ${page.padEnd(9)} ${lib.padEnd(11)} drawn ${row.drawn?.toFixed(0)} ms, blocking ${row.blocking?.toFixed(0) ?? "-"} ms, update ${row.updateMs?.toFixed(0)} ms / ${row.updateBytes} B`,
      );
    }
  }
  await browser.close();
}

writeFileSync(args.out ?? "../results/browser.json", JSON.stringify(results, null, 2));
