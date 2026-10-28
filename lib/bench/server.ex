defmodule Bench.Server do
  @moduledoc """
  What the server does for a chart: the time to build it and render it to
  HTML (the median of many runs, after warming up), and the HTML it sends,
  raw and gzipped. Also the size of each library's files.
  """

  @runs 30

  def start do
    # Mix starts the logger before it reads config/, so the level is set here.
    Logger.configure(level: :warning)
    Application.ensure_all_started(:bench)

    {:ok, _} =
      Supervisor.start_link([{Phoenix.PubSub, name: Bench.PubSub}, BenchWeb.Endpoint], strategy: :one_for_one)

    :ok
  end

  def measure do
    for key <- Bench.Lib.keys(), {:ok, lib} = Bench.Lib.fetch(key), kase <- Bench.Data.cases() do
      rows = Bench.Data.rows(kase)
      assigns = %{__changed__: nil, id: "chart", kind: kase, rows: rows, width: 640, height: 320}
      html = render(lib, assigns)
      for _ <- 1..3, do: render(lib, assigns)
      times = for _ <- 1..@runs, do: elem(:timer.tc(fn -> render(lib, assigns) end), 0)

      %{
        lib: key,
        case: kase,
        render_ms: median(times) / 1000,
        html_bytes: byte_size(html),
        html_gzip_bytes: byte_size(:zlib.gzip(html))
      }
    end
  end

  def assets do
    for key <- Bench.Lib.keys(), {:ok, lib} = Bench.Lib.fetch(key) do
      files = for {_, _, path} <- lib.assets(), do: File.read!(path)

      %{
        lib: key,
        name: lib.name(),
        version: Bench.Lib.version(lib),
        bytes: files |> Enum.map(&byte_size/1) |> Enum.sum(),
        gzip_bytes: files |> Enum.map(&byte_size(:zlib.gzip(&1))) |> Enum.sum()
      }
    end
  end

  defp render(lib, assigns) do
    assigns |> lib.chart() |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  defp median(list), do: list |> Enum.sort() |> Enum.at(div(length(list), 2))
end
