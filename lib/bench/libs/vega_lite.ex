defmodule Bench.Libs.VegaLite do
  @moduledoc """
  VegaLite: the spec built on the server with the `vega_lite` package and
  drawn by vega-embed (canvas renderer, its default) in a hook. The package
  has no LiveView component; the hook is the usual one: embed the spec on
  mount, and again when the render gives a new spec.
  """
  @behaviour Bench.Lib
  use Phoenix.Component
  alias VegaLite, as: Vl

  @impl true
  def name, do: "VegaLite"
  @impl true
  def package, do: :vega_lite
  @impl true
  def server_drawn?, do: false

  @impl true
  def chart(assigns) do
    assigns =
      assign(
        assigns,
        :spec,
        assigns.kind |> build(assigns.rows, assigns.width, assigns.height) |> Vl.to_spec() |> Jason.encode!()
      )

    ~H"""
    <div id={@id} phx-hook="VegaLite" data-spec={@spec}>
      <div id={"#{@id}-view"} phx-update="ignore"></div>
    </div>
    """
  end

  def build(kind, rows, width, height) do
    Vl.new(width: width, height: height, autosize: [type: :fit, contains: :padding])
    |> Vl.data_from_values(rows)
    |> encode(kind)
  end

  defp encode(vl, :scatter) do
    vl
    |> Vl.mark(:point)
    |> Vl.encode_field(:x, "x", type: :quantitative)
    |> Vl.encode_field(:y, "y", type: :quantitative)
    |> Vl.encode_field(:color, "group", type: :nominal)
  end

  defp encode(vl, :lines) do
    vl
    |> Vl.mark(:line)
    |> Vl.encode_field(:x, "date", type: :temporal)
    |> Vl.encode_field(:y, "value", type: :quantitative)
    |> Vl.encode_field(:color, "series", type: :nominal)
  end

  defp encode(vl, :bars) do
    vl
    |> Vl.mark(:bar)
    |> Vl.encode_field(:x, "name", type: :nominal)
    |> Vl.encode_field(:y, "value", type: :quantitative)
  end

  @impl true
  def assets do
    dir = Path.expand("../../../browser/node_modules", __DIR__)

    [
      {:js, "/libs/vega/vega.min.js", Path.join(dir, "vega/build/vega.min.js")},
      {:js, "/libs/vega/vega-lite.min.js", Path.join(dir, "vega-lite/build/vega-lite.min.js")},
      {:js, "/libs/vega/vega-embed.min.js", Path.join(dir, "vega-embed/build/vega-embed.min.js")}
    ]
  end

  @impl true
  def hooks do
    """
    const embed = async (hook, kind) => {
      const spec = JSON.parse(hook.el.dataset.spec)
      hook.view?.finalize()
      const result = await vegaEmbed(hook.el.firstElementChild, spec, { actions: false })
      hook.view = result.view
      mark(kind, hook.el.id)
    }
    hooks.VegaLite = {
      mounted() { embed(this, "drawn") },
      updated() { embed(this, "updated") },
      destroyed() { this.view?.finalize() },
    }
    """
  end

  @impl true
  def push(_socket, _id, _kind, _rows), do: nil
end
