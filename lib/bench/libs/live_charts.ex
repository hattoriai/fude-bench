defmodule Bench.Libs.LiveCharts do
  @moduledoc """
  LiveCharts: the ApexCharts config built on the server, drawn by
  ApexCharts (SVG) in the package's hook; new data goes by
  `LiveCharts.push_update/3`, as its README shows.
  """
  @behaviour Bench.Lib
  use Phoenix.Component

  @impl true
  def name, do: "LiveCharts (ApexCharts)"
  @impl true
  def package, do: :live_charts
  @impl true
  def server_drawn?, do: false

  @impl true
  def chart(assigns) do
    assigns = assign(assigns, :chart, build(assigns.id, assigns.kind, assigns.rows, assigns.height))

    ~H"""
    <div style={"width: #{@width}px; height: #{@height}px"}>
      <LiveCharts.Components.chart chart={@chart} />
    </div>
    """
  end

  def build(id, kind, rows, height) do
    LiveCharts.build(%{
      id: id,
      type: type(kind),
      series: series(kind, rows),
      options: options(kind, rows, height)
    })
  end

  defp type(:scatter), do: :scatter
  defp type(:lines), do: :line
  defp type(:bars), do: :bar

  def series(:scatter, rows) do
    for {group, points} <- Enum.group_by(rows, & &1.group) |> Enum.sort(),
        do: %{name: group, data: Enum.map(points, &[&1.x, &1.y])}
  end

  def series(:lines, rows) do
    for {name, points} <- Enum.group_by(rows, & &1.series) |> Enum.sort(),
        do: %{name: name, data: Enum.map(points, &[ms(&1.date), &1.value])}
  end

  def series(:bars, rows), do: [%{name: "value", data: Enum.map(rows, & &1.value)}]

  defp ms(date), do: date |> DateTime.new!(~T[00:00:00]) |> DateTime.to_unix(:millisecond)

  defp options(kind, rows, height) do
    base = %{chart: %{height: height, animations: %{enabled: false}}}

    case kind do
      :scatter -> Map.put(base, :xaxis, %{type: "numeric", tickAmount: 10})
      :lines -> Map.put(base, :xaxis, %{type: "datetime"})
      :bars -> Map.merge(base, %{xaxis: %{categories: Enum.map(rows, & &1.name)}, dataLabels: %{enabled: false}})
    end
  end

  @impl true
  def assets do
    dir = Application.app_dir(:live_charts, "priv/static")
    [{:js, "/libs/live_charts/live_charts.min.js", Path.join(dir, "live_charts.min.js")}]
  end

  # The package's hook, with ApexCharts' own events (mounted, updated) marking
  # when the chart is drawn.
  @impl true
  def hooks do
    """
    const Apex = LiveCharts.default.Hooks["LiveCharts.Hooks.ApexCharts"]
    hooks["LiveCharts.Hooks.ApexCharts"] = {
      ...Apex,
      getConfig() {
        const config = Apex.getConfig.call(this)
        const id = this.el.id
        config.chart.events = { ...config.chart.events, mounted: () => mark("drawn", id), updated: () => mark("updated", id) }
        return config
      },
    }
    """
  end

  @impl true
  def push(socket, id, kind, rows), do: LiveCharts.push_update(socket, id, series(kind, rows))
end
