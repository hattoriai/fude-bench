# Results

Run on 2026-10-28: Elixir 1.18.4, OTP 25, 4 schedulers, x86_64-pc-linux-gnu.
Fude: checkout at f9a23f0.
Browser: chromium 153.0.8010.12; median of 7 runs.

## What each library loads

| Library | Version | JS + CSS | gzipped |
| --- | --- | --- | --- |
| Fude | 0.8.0 | 123.9 KB | 40.8 KB |
| VegaLite | 0.1.11 | 819.7 KB | 276.2 KB |
| Contex | 0.5.0 | 0.0 KB | 0.0 KB |
| LiveCharts (ApexCharts) | 0.5.0 | 776.6 KB | 220.6 KB |

Phoenix and LiveView, the same for every library, are not counted.

## On the server

Building the chart and rendering it to HTML (the median of 30 runs), and the HTML of the chart.

| Case | Library | Build + render | HTML | gzipped |
| --- | --- | --- | --- | --- |
| scatter | Fude | 4.55 ms | 15.3 KB | 5.8 KB |
| lines | Fude | 16.91 ms | 87.9 KB | 14.1 KB |
| bars | Fude | 1.05 ms | 6.9 KB | 1.8 KB |
| scatter | VegaLite | 3.57 ms | 76.3 KB | 8.2 KB |
| lines | VegaLite | 27.41 ms | 401.1 KB | 24.0 KB |
| bars | VegaLite | 0.30 ms | 12.5 KB | 1.3 KB |
| scatter | Contex | 2.33 ms | 82.2 KB | 11.4 KB |
| lines | Contex | 20.02 ms | 174.2 KB | 62.4 KB |
| bars | Contex | 2.67 ms | 64.0 KB | 4.5 KB |
| scatter | LiveCharts (ApexCharts) | 0.47 ms | 14.1 KB | 5.9 KB |
| lines | LiveCharts (ApexCharts) | 3.87 ms | 86.6 KB | 21.3 KB |
| bars | LiveCharts (ApexCharts) | 0.08 ms | 5.2 KB | 1.1 KB |

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
| chromium | Fude | 183 ms | 151 ms | 0 ms | 2.1 MB | 65 | 31 ms | 15.4 KB | 17.8 KB | 16.1 KB |
| chromium | VegaLite | 374 ms | 194 ms | 118 ms | 6.3 MB | 1176 | 101 ms | 76.4 KB | 79.0 KB | 76.7 KB |
| chromium | Contex | 68 ms | 161 ms | 9 ms | 1.9 MB | 1091 | 57 ms | 90.6 KB | 84.4 KB | 90.7 KB |
| chromium | LiveCharts (ApexCharts) | 234 ms | 215 ms | 74 ms | 3.1 MB | 1230 | 86 ms | 13.7 KB | 16.7 KB | 14.5 KB |

### Lines, 4 series × 1,000 days

| Browser | Library | Drawn | Connected | Blocking | Heap | DOM | Update | Update bytes | Page | Join |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| chromium | Fude | 160 ms | 135 ms | 0 ms | 2.5 MB | 70 | 48 ms | 87.9 KB | 90.3 KB | 88.7 KB |
| chromium | VegaLite | 304 ms | 194 ms | 83 ms | 8.3 MB | 184 | 98 ms | 401.1 KB | 403.8 KB | 401.4 KB |
| chromium | Contex | 88 ms | 132 ms | 0 ms | 2.1 MB | 82 | 39 ms | 174.6 KB | 176.4 KB | 174.9 KB |
| chromium | LiveCharts (ApexCharts) | 172 ms | 168 ms | 21 ms | 3.3 MB | 236 | 36 ms | 86.2 KB | 89.2 KB | 87.0 KB |

### Bars, 200 categories

| Browser | Library | Drawn | Connected | Blocking | Heap | DOM | Update | Update bytes | Page | Join |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| chromium | Fude | 109 ms | 88 ms | 0 ms | 2.1 MB | 57 | 16 ms | 6.9 KB | 9.3 KB | 7.7 KB |
| chromium | VegaLite | 198 ms | 107 ms | 31 ms | 5.1 MB | 676 | 32 ms | 12.6 KB | 15.2 KB | 12.9 KB |
| chromium | Contex | 40 ms | 84 ms | 0 ms | 1.8 MB | 1056 | 31 ms | 69.7 KB | 66.2 KB | 70.0 KB |
| chromium | LiveCharts (ApexCharts) | 225 ms | 210 ms | 98 ms | 3.2 MB | 1112 | 30 ms | 0.7 KB | 7.8 KB | 5.6 KB |

### Dashboard, 12 small charts (4 bars, 4 lines, 4 scatters)

| Browser | Library | Drawn | Connected | Blocking | Heap | DOM | Update | Update bytes | Page | Join |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| chromium | Fude | 194 ms | 153 ms | 29 ms | 2.7 MB | 562 | 45 ms | 45.3 KB | 48.7 KB | 46.8 KB |
| chromium | VegaLite | 417 ms | 155 ms | 208 ms | 13.1 MB | 1866 | 176 ms | 128.2 KB | 131.5 KB | 128.6 KB |
| chromium | Contex | 68 ms | 139 ms | 0 ms | 1.9 MB | 1619 | 50 ms | 137.3 KB | 131.9 KB | 139.7 KB |
| chromium | LiveCharts (ApexCharts) | 289 ms | 273 ms | 146 ms | 5.2 MB | 2659 | 86 ms | 24.9 KB | 34.1 KB | 32.2 KB |
