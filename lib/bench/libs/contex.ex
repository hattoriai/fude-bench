defmodule Bench.Libs.Contex do
  @moduledoc "Contex: the chart drawn on the server as SVG, sent in the page and in each render."
  @behaviour Bench.Lib
  use Phoenix.Component
  alias Contex.{Dataset, Plot}

  @impl true
  def name, do: "Contex"
  @impl true
  def package, do: :contex
  @impl true
  def server_drawn?, do: true

  @impl true
  def chart(assigns) do
    assigns = assign(assigns, :svg, assigns.kind |> build(assigns.rows, assigns.width, assigns.height) |> Plot.to_svg())

    ~H"""
    <div id={@id} phx-hook="Mark" style={"width: #{@width}px"}>{@svg}</div>
    """
  end

  def build(:scatter, rows, width, height) do
    rows
    |> Enum.map(&[&1.x, &1.y, &1.group])
    |> Dataset.new(["x", "y", "group"])
    |> Plot.new(Contex.PointPlot, width, height,
      mapping: %{x_col: "x", y_cols: ["y"], fill_col: "group"},
      legend_setting: :legend_right
    )
  end

  # A line plot takes wide rows: one column of values for each series.
  def build(:lines, rows, width, height) do
    series = rows |> Enum.map(& &1.series) |> Enum.uniq()

    rows
    |> Enum.group_by(& &1.date, &{&1.series, &1.value})
    |> Enum.sort_by(&elem(&1, 0), Date)
    |> Enum.map(fn {date, values} ->
      [NaiveDateTime.new!(date, ~T[00:00:00]) | Enum.map(series, &:proplists.get_value(&1, values))]
    end)
    |> Dataset.new(["date" | series])
    |> Plot.new(Contex.LinePlot, width, height,
      mapping: %{x_col: "date", y_cols: series},
      legend_setting: :legend_right
    )
  end

  # Without the value on each bar (its default), as the other libraries draw them.
  def build(:bars, rows, width, height) do
    rows
    |> Enum.map(&[&1.name, &1.value])
    |> Dataset.new(["name", "value"])
    |> Plot.new(Contex.BarChart, width, height,
      mapping: %{category_col: "name", value_cols: ["value"]},
      data_labels: false
    )
  end

  # No script: the hook only marks when a render has changed the chart.
  @impl true
  def assets, do: []

  @impl true
  def hooks do
    """
    hooks.Mark = { updated() { mark("updated", this.el.id) } }
    """
  end

  @impl true
  def push(_socket, _id, _kind, _rows), do: nil
end
