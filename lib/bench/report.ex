defmodule Bench.Report do
  @moduledoc "The results as Markdown: results/REPORT.md."

  @pages ~w(scatter lines bars dashboard)
  @titles %{
    "scatter" => "Scatter, 1,000 points in 3 groups",
    "lines" => "Lines, 4 series × 1,000 days",
    "bars" => "Bars, 200 categories",
    "dashboard" => "Dashboard, 12 small charts (4 bars, 4 lines, 4 scatters)"
  }

  def markdown(server, browser) do
    libs = Map.new(server.assets, &{&1.lib, &1})

    [
      "# Results\n\n",
      env(server.env, browser),
      "\n## What each library loads\n\n",
      table(
        ["Library", "Version", "JS + CSS", "gzipped"],
        for(a <- server.assets, do: [a.name, a.version, kb(a.bytes), kb(a.gzip_bytes)])
      ),
      "\nPhoenix and LiveView, the same for every library, are not counted.\n",
      "\n## On the server\n\nBuilding the chart and rendering it to HTML (the median of 30 runs), and the HTML of the chart.\n\n",
      table(
        ["Case", "Library", "Build + render", "HTML", "gzipped"],
        for(
          c <- server.charts,
          do: [to_string(c.case), libs[c.lib].name, ms(c.render_ms, 2), kb(c.html_bytes), kb(c.html_gzip_bytes)]
        )
      ),
      if(browser, do: browser_tables(browser, libs), else: "")
    ]
    |> IO.iodata_to_binary()
  end

  defp env(env, browser) do
    browsers =
      if browser,
        do:
          browser
          |> Enum.filter(fn {k, _} -> String.ends_with?(k, "Version") end)
          |> Enum.map_join(", ", fn {k, v} -> "#{String.replace(k, "Version", "")} #{v}" end),
        else: "not run"

    """
    Run on #{env.date}: Elixir #{env.elixir}, OTP #{env.otp}, #{env.schedulers} schedulers, #{env.system}.
    Fude: #{env.fude}.
    Browser: #{browsers}#{if browser, do: "; median of #{browser["runs"]} runs#{if browser["cpu"] > 1, do: ", CPU slowed #{browser["cpu"]}×"}", else: ""}.
    """
  end

  defp browser_tables(browser, libs) do
    rows = browser["rows"]

    [
      """

      ## In the browser

      * **Drawn**: from navigation to the last chart painted (Contex: the first contentful paint, since its SVG is in the HTML).
      * **Connected**: when LiveView joined; a hook draws only after it.
      * **Blocking**: main-thread time in long tasks beyond 50 ms each, until drawn (Chromium only).
      * **Heap**: JS heap after a forced GC (Chromium only). **DOM**: elements on the page.
      * **Update**: from the click to the last chart painted with new data, and the bytes the LiveView socket received for it.
      * **Page**: the HTML of the first (dead) render; **join**: the bytes of LiveView's connected render over the socket.
      """
      | for page <- @pages, Enum.any?(rows, &(&1["page"] == page)) do
          [
            "\n### #{@titles[page]}\n\n",
            table(
              [
                "Browser",
                "Library",
                "Drawn",
                "Connected",
                "Blocking",
                "Heap",
                "DOM",
                "Update",
                "Update bytes",
                "Page",
                "Join"
              ],
              for r <- rows, r["page"] == page do
                [
                  r["browser"],
                  libs[r["lib"]].name,
                  ms(r["drawn"]),
                  ms(r["connected"]),
                  ms(r["blocking"]),
                  if(r["heapMB"], do: "#{Float.round(r["heapMB"] * 1.0, 1)} MB", else: "–"),
                  to_string(r["nodes"]),
                  ms(r["updateMs"]),
                  kb(r["updateBytes"]),
                  kb(r["htmlBytes"]),
                  kb(r["joinBytes"])
                ]
              end
            )
          ]
        end
    ]
  end

  defp table(heads, rows) do
    line = fn cells -> "| " <> Enum.join(cells, " | ") <> " |\n" end
    [line.(heads), line.(Enum.map(heads, fn _ -> "---" end)) | Enum.map(rows, line)]
  end

  defp ms(nil), do: "–"
  defp ms(value, digits \\ 0), do: "#{:erlang.float_to_binary(value * 1.0, decimals: digits)} ms"

  defp kb(nil), do: "–"
  defp kb(bytes), do: "#{:erlang.float_to_binary(bytes / 1024, decimals: 1)} KB"
end
