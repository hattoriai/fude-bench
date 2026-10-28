# fude-bench

Benchmarks of the charting libraries for Phoenix LiveView, measured the same
way in the same app:

| Library | How it draws |
| --- | --- |
| [Fude](https://hex.pm/packages/fude) | Compiled on the server to a JSON config; a hook draws marks on a canvas and text in SVG |
| [VegaLite](https://hex.pm/packages/vega_lite) | A Vega-Lite spec built on the server; vega-embed draws it in a hook (canvas) |
| [Contex](https://hex.pm/packages/contex) | SVG drawn on the server, sent in the HTML |
| [LiveCharts](https://hex.pm/packages/live_charts) | An ApexCharts config built on the server; ApexCharts (bundled) draws it in the package's hook (SVG) |

The latest results are in [results/REPORT.md](results/REPORT.md).

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
