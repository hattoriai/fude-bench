# Results

Run on 2026-10-28: Elixir 1.18.4, OTP 25, 4 schedulers, x86_64-pc-linux-gnu.
Fude: checkout at 28f770b.
Browser: chromium 153.0.8010.12; median of 7 runs.

## What each library loads

| Library | Version | JS + CSS | gzipped |
| --- | --- | --- | --- |
| Fude | 0.8.0 | 135.3 KB | 44.3 KB |
| VegaLite | 0.1.11 | 819.7 KB | 276.2 KB |
| Contex | 0.5.0 | 0.0 KB | 0.0 KB |
| LiveCharts (ApexCharts) | 0.5.0 | 776.6 KB | 220.6 KB |

Phoenix and LiveView, the same for every library, are not counted.

## On the server

Building the chart and rendering it to HTML (the median of 30 runs), and the HTML of the chart.

| Case | Library | Build + render | HTML | gzipped |
| --- | --- | --- | --- | --- |
| scatter | Fude | 4.24 ms | 14.1 KB | 5.7 KB |
| lines | Fude | 15.86 ms | 35.4 KB | 8.7 KB |
| bars | Fude | 0.74 ms | 6.7 KB | 1.5 KB |
| scatter | VegaLite | 2.29 ms | 76.3 KB | 8.2 KB |
| lines | VegaLite | 19.22 ms | 401.1 KB | 24.0 KB |
| bars | VegaLite | 0.44 ms | 12.5 KB | 1.3 KB |
| scatter | Contex | 1.72 ms | 82.2 KB | 11.4 KB |
| lines | Contex | 15.31 ms | 174.2 KB | 62.4 KB |
| bars | Contex | 2.54 ms | 64.0 KB | 4.5 KB |
| scatter | LiveCharts (ApexCharts) | 0.36 ms | 14.1 KB | 5.9 KB |
| lines | LiveCharts (ApexCharts) | 5.03 ms | 86.6 KB | 21.3 KB |
| bars | LiveCharts (ApexCharts) | 0.12 ms | 5.2 KB | 1.1 KB |

## In the browser

* **Drawn**: from navigation to the last chart painted (Contex: the first contentful paint, since its SVG is in the HTML).
* **Connected**: when LiveView joined; a hook draws only after it.
* **Blocking**: main-thread time in long tasks beyond 50 ms each, until drawn (Chromium only).
* **Heap**: JS heap after a forced GC (Chromium only). **DOM**: elements on the page.
* **Update**: from the click to the last chart painted with new data, and the bytes the LiveView socket received for it.
* **Page**: the HTML of the first (dead) render; **join**: the bytes of LiveView's connected render over the socket.

### Scatter, 1,000 points in 3 groups

| Browser | Library | Drawn | Connected | Blocking | Heap | DOM | Update | Update bytes | Page | Join |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| chromium | Fude | 134 ms | 111 ms | 0 ms | 2.1 MB | 65 | 21 ms | 14.2 KB | 16.6 KB | 15.0 KB |
| chromium | VegaLite | 271 ms | 135 ms | 78 ms | 6.3 MB | 1176 | 72 ms | 76.4 KB | 79.1 KB | 76.7 KB |
| chromium | Contex | 52 ms | 110 ms | 0 ms | 1.9 MB | 1091 | 42 ms | 90.6 KB | 84.4 KB | 90.7 KB |
| chromium | LiveCharts (ApexCharts) | 198 ms | 183 ms | 49 ms | 3.1 MB | 1230 | 64 ms | 13.7 KB | 16.7 KB | 14.5 KB |

### Lines, 4 series × 1,000 days

| Browser | Library | Drawn | Connected | Blocking | Heap | DOM | Update | Update bytes | Page | Join |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| chromium | Fude | 167 ms | 140 ms | 0 ms | 2.4 MB | 70 | 49 ms | 35.4 KB | 37.8 KB | 36.2 KB |
| chromium | VegaLite | 340 ms | 229 ms | 96 ms | 8.3 MB | 184 | 111 ms | 401.1 KB | 403.8 KB | 401.4 KB |
| chromium | Contex | 100 ms | 144 ms | 0 ms | 2.1 MB | 82 | 42 ms | 174.6 KB | 176.4 KB | 174.9 KB |
| chromium | LiveCharts (ApexCharts) | 185 ms | 180 ms | 25 ms | 3.3 MB | 236 | 37 ms | 86.2 KB | 89.2 KB | 87.0 KB |

### Bars, 200 categories

| Browser | Library | Drawn | Connected | Blocking | Heap | DOM | Update | Update bytes | Page | Join |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| chromium | Fude | 117 ms | 94 ms | 0 ms | 2.1 MB | 57 | 14 ms | 6.7 KB | 9.1 KB | 7.5 KB |
| chromium | VegaLite | 215 ms | 106 ms | 38 ms | 5.1 MB | 676 | 38 ms | 12.6 KB | 15.2 KB | 12.9 KB |
| chromium | Contex | 44 ms | 98 ms | 0 ms | 1.8 MB | 1056 | 32 ms | 69.7 KB | 66.2 KB | 70.0 KB |
| chromium | LiveCharts (ApexCharts) | 209 ms | 193 ms | 81 ms | 3.2 MB | 1112 | 30 ms | 0.7 KB | 7.8 KB | 5.6 KB |

### Dashboard, 12 small charts (4 bars, 4 lines, 4 scatters)

| Browser | Library | Drawn | Connected | Blocking | Heap | DOM | Update | Update bytes | Page | Join |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| chromium | Fude | 221 ms | 178 ms | 41 ms | 2.7 MB | 562 | 51 ms | 36.3 KB | 39.7 KB | 37.8 KB |
| chromium | VegaLite | 439 ms | 153 ms | 231 ms | 13.1 MB | 1866 | 167 ms | 128.2 KB | 131.5 KB | 128.6 KB |
| chromium | Contex | 68 ms | 142 ms | 4 ms | 1.9 MB | 1619 | 54 ms | 137.3 KB | 131.9 KB | 139.7 KB |
| chromium | LiveCharts (ApexCharts) | 334 ms | 309 ms | 179 ms | 5.2 MB | 2659 | 84 ms | 24.9 KB | 34.1 KB | 32.2 KB |
