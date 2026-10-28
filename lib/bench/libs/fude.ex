defmodule Bench.Libs.Fude do
  @moduledoc "Fude: the chart compiled on the server, drawn by its hook on a canvas."
  @behaviour Bench.Lib
  use Phoenix.Component

  @impl true
  def name, do: "Fude"
  @impl true
  def package, do: :fude
  @impl true
  def server_drawn?, do: false

  @impl true
  def chart(assigns) do
    assigns = assign(assigns, :chart, build(assigns.kind, assigns.rows))

    ~H"""
    <div style={"width: #{@width}px"}>
      <Fude.Components.chart id={@id} chart={@chart} height={@height} animate={false} />
    </div>
    """
  end

  def build(:scatter, rows), do: Fude.scatter(rows, x: :x, y: :y, color: :group)
  def build(:lines, rows), do: Fude.line(rows, x: :date, y: :value, color: :series)
  def build(:bars, rows), do: Fude.bar(rows, x: :name, y: :value)

  @impl true
  def assets do
    dir = Application.app_dir(:fude, "priv/static")

    [
      {:css, "/libs/fude/fude.css", Path.join(dir, "fude.css")},
      {:module, "/libs/fude/fude.esm.js", Path.join(dir, "fude.esm.js")}
    ]
  end

  @impl true
  def hooks do
    """
    import { Fude } from "/libs/fude/fude.esm.js"
    hooks.Fude = {
      ...Fude,
      mounted() { Fude.mounted.call(this); mark("drawn", this.el.id) },
      updated() { Fude.updated.call(this); mark("updated", this.el.id) },
    }
    """
  end

  @impl true
  def push(_socket, _id, _kind, _rows), do: nil
end
