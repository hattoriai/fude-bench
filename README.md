# fude-bench

Benchmarks of the charting libraries for Phoenix LiveView, measured the same
way in the same app:

| Library | How it draws |
| --- | --- |
| [Fude](https://hex.pm/packages/fude) | Compiled on the server to a JSON config; a hook draws marks on a canvas and text in SVG |
| [VegaLite](https://hex.pm/packages/vega_lite) | A Vega-Lite spec built on the server; vega-embed draws it in a hook (canvas) |
| [Contex](https://hex.pm/packages/contex) | SVG drawn on the server, sent in the HTML |
| [LiveCharts](https://hex.pm/packages/live_charts) | An ApexCharts config built on the server; ApexCharts (bundled) draws it in the package's hook (SVG) |

## Results

Run on 2026-10-28 with Fude at
[`28f770b`](https://github.com/hattoriai/fude/commit/28f770b) (`main`),
VegaLite 0.1.11 (Vega-Lite 6.5, Vega 6.4), Contex 0.5.0 and LiveCharts
0.5.0 (ApexCharts 6.5.0); Chromium 153, the median of 7 runs, served from
localhost. Every table, and the server's times, are in
[results/REPORT.md](results/REPORT.md).

**What each library loads** (JS and CSS, gzipped; Phoenix and LiveView
not counted):

| Fude | VegaLite | Contex | LiveCharts |
| --- | --- | --- | --- |
| 44.3 KB | 276.2 KB | none (SVG from the server) | 220.6 KB |

**In the browser**: when the last chart is painted, main-thread time
blocked, JS heap, and an update of the data (time, and bytes over the
LiveView socket).

| Case | Library | Drawn | Blocking | Heap | DOM | Update | Update bytes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Scatter, 1,000 points | Fude | 134 ms | 0 ms | 2.1 MB | 65 | 21 ms | 14.2 KB |
| | VegaLite | 271 ms | 78 ms | 6.3 MB | 1,176 | 72 ms | 76.4 KB |
| | Contex | 52 ms | 0 ms | 1.9 MB | 1,091 | 42 ms | 90.6 KB |
| | LiveCharts | 198 ms | 49 ms | 3.1 MB | 1,230 | 64 ms | 13.7 KB |
| Lines, 4 × 1,000 days | Fude | 167 ms | 0 ms | 2.4 MB | 70 | 49 ms | 35.4 KB |
| | VegaLite | 340 ms | 96 ms | 8.3 MB | 184 | 111 ms | 401.1 KB |
| | Contex | 100 ms | 0 ms | 2.1 MB | 82 | 42 ms | 174.6 KB |
| | LiveCharts | 185 ms | 25 ms | 3.3 MB | 236 | 37 ms | 86.2 KB |
| Bars, 200 | Fude | 117 ms | 0 ms | 2.1 MB | 57 | 14 ms | 6.7 KB |
| | VegaLite | 215 ms | 38 ms | 5.1 MB | 676 | 38 ms | 12.6 KB |
| | Contex | 44 ms | 0 ms | 1.8 MB | 1,056 | 32 ms | 69.7 KB |
| | LiveCharts | 209 ms | 81 ms | 3.2 MB | 1,112 | 30 ms | 0.7 KB |
| Dashboard, 12 charts | Fude | 221 ms | 41 ms | 2.7 MB | 562 | 51 ms | 36.3 KB |
| | VegaLite | 439 ms | 231 ms | 13.1 MB | 1,866 | 167 ms | 128.2 KB |
| | Contex | 68 ms | 4 ms | 1.9 MB | 1,619 | 54 ms | 137.3 KB |
| | LiveCharts | 334 ms | 179 ms | 5.2 MB | 2,659 | 84 ms | 24.9 KB |

What they show:

* **Contex is on the screen first**: its SVG is in the page's HTML, drawn
  before LiveView connects. It sends the most (the whole SVG in the page,
  the join and every update) and has the largest DOM.
* **Of the libraries that draw in the browser, Fude draws first** and
  blocks the main thread least, with the smallest heap and DOM: it loads
  a sixth of the JavaScript, and the server has done the work (scales,
  aggregates) that Vega and ApexCharts do in the page.
* **What an update sends** depends on how the library takes new data.
  LiveCharts pushes only the new series (`push_update`), so 200 bars are
  0.7 KB; Fude and Contex render again and send the chart that changed,
  Fude's long columns packed (35 KB for 4,000 points, against Vega-Lite's
  401 KB).

Times are on one machine and change from run to run by about ten percent;
compare the libraries within a run, not runs with each other.

## Running

Requires Elixir 1.18+, Node.js 20+ and Playwright's browsers.

```sh
mix setup                        # deps.get and npm install in browser/
npx --prefix browser playwright install chromium
mix bench                        # writes results/
```

`mix bench` measures on the server, starts the app on port 4200, loads
every page in a browser and writes `results/server.json`,
`results/browser.json` and `results/REPORT.md`, with a screenshot of each
page in `results/screenshots/` (not committed). Options:

```sh
mix bench --runs 7                          # runs per page (the median is reported)
mix bench --browsers chromium,firefox,webkit
mix bench --libs fude,contex
mix bench --server-only
```

`mix bench.serve` serves the pages to look at, at <http://localhost:4200>.
The runner can also be run against a running server:
`cd browser && node run.mjs --cpu 4` (CPU slowed 4×, Chromium only).

### Measuring unreleased Fude

Fude comes from Hex. To measure a checkout, build its bundle there and
point `FUDE_PATH` at it:

```sh
(cd ../fude && MIX_ENV=dev mix fude.build)
FUDE_PATH=../fude mix deps.get
FUDE_PATH=../fude mix bench
```

The report says which Fude it measured: the Hex version or the commit of the
checkout.

## The cases

The same rows go to every library (`Bench.Data`, made up, the same on every
run):

* **scatter**: 1,000 points in 3 groups.
* **lines**: 4 series of 1,000 days.
* **bars**: 200 categories.
* **dashboard**: 12 small charts on one page (4 of each kind, 90 days, 150
  points, 12 bars).

The single charts are 640 × 320 px; the dashboard's are 320 × 180 px. The
"Update data" button on each page gives every chart new rows of the same
shape (a new seed).

## What is measured

On the server (`Bench.Server`), for each chart:

* **Build + render**: building the chart from the rows and rendering the
  component to HTML, the median of 30 runs after warming up.
* **HTML**: the chart's HTML, raw and gzipped.

In the browser (`browser/run.mjs`), the median of the runs, each in a new
browser context:

* **Drawn**: from navigation to the last chart painted. Each library's hook
  calls `mark("drawn", id)` when its chart is drawn (see below), and the time
  is taken after the next frame, so the paint is included. Contex's SVG is in
  the page's HTML, so it is drawn at the first contentful paint.
* **Connected**: when LiveView joined. A hook draws only after it.
* **Blocking**: the main thread's time in long tasks beyond 50 ms each
  (as in Total Blocking Time), until drawn. Chromium only.
* **Heap**: the JS heap after a forced GC. Chromium only.
* **DOM**: the elements on the page.
* **Update**: from the click to the last chart painted with the new data,
  the median of 3 updates, and the bytes the LiveView socket received for it.
* **Page / Join**: the bytes of the first (dead) render's HTML, and of
  LiveView's connected render over the socket.
* **What each library loads**: its JS and CSS, raw and gzipped. Phoenix and
  LiveView are the same for every library and are not counted.

### When a chart counts as drawn

| Library | Drawn | Updated |
| --- | --- | --- |
| Fude | after the hook's `mounted` (it draws synchronously with animations off) | after the hook's `updated` |
| VegaLite | when `vegaEmbed` resolves | when `vegaEmbed` resolves again |
| Contex | first contentful paint | a hook's `updated`, after LiveView patched the SVG |
| LiveCharts | ApexCharts' `mounted` event | ApexCharts' `updated` event |

## Fairness

Each library draws each case the way its own documentation shows, with its
defaults, except:

* The same size for all, and animations off (Fude `animate={false}`,
  ApexCharts `chart.animations.enabled: false`; Vega and Contex don't
  animate).
* Contex's bar chart without its default value on each bar, and
  ApexCharts' bar chart without its data labels (its README's example), as
  the others draw 200 bars.
* ApexCharts' scatter with a numeric x axis (`xaxis.type: "numeric"`), as
  its scatter examples have it; without it, every x value is a label.

How each library updates is the way its documentation shows:

* **Fude** and **Contex**: the LiveView assigns new rows and re-renders.
* **VegaLite**: the package has no LiveView component; the hook is the usual
  one, which embeds the spec again when a render gives a new one
  (`data-spec`).
* **LiveCharts**: `LiveCharts.push_update/3` with the new series, as its
  README shows; the render does not change.

Each library's files are served as built by its authors: Fude's
`fude.esm.js` and `fude.css`; LiveCharts' `live_charts.min.js` (ApexCharts
included); Vega's, Vega-Lite's and vega-embed's minified builds from npm (the
versions in `browser/package.json`). The `vega_lite` package writes a
Vega-Lite v5 `$schema`; Vega-Lite 6 draws it with a warning.

Every library is in `lib/bench/libs/`, one module each, with its hook in
`hooks/0`. If a library is not drawn the way its authors would draw it,
change its module and say why in a pull request.

## Not measured (yet)

* Firefox and WebKit by default (`--browsers` runs them; blocking and heap
  are Chromium only).
* A slow network. The pages are served from localhost, so the size of what a
  library loads shows in the tables, not in the times.
* Interaction (tooltips, zoom) and accessibility, which differ in kind
  between the libraries rather than in speed.
