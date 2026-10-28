defmodule Bench.Lib do
  @moduledoc """
  A charting library under test: how it draws a case, what the page loads
  for it, and how a page changes its data.

  Each library draws each case the way its own documentation shows, at the
  same size (640 × 320), with animations off. Change a library's module
  here if it is not drawn the way its authors would draw it.
  """

  @doc "The name in reports."
  @callback name() :: String.t()

  @doc "The package and version measured."
  @callback package() :: atom()

  @doc """
  The chart of `kind` (`:scatter`, `:lines`, `:bars`) for `rows`, as
  rendered by the library's component or function: `assigns` has `id`,
  `kind`, `rows`, `width` and `height`.
  """
  @callback chart(assigns :: map()) :: Phoenix.LiveView.Rendered.t()

  @doc """
  The files the page loads for the library, as `{type, url, path}` with
  type `:js` (a classic script), `:module` or `:css`; served from the path.
  """
  @callback assets() :: [{:js | :module | :css, String.t(), String.t()}]

  @doc """
  How the library's hook is given to the LiveSocket, as JavaScript that
  sets `hooks` (with `mark("drawn" | "updated", id)` in scope).
  """
  @callback hooks() :: String.t()

  @doc """
  New data for a chart already drawn, when the library sends it by an
  event (`push_event`) rather than by a render; nil when a render does.
  """
  @callback push(Phoenix.LiveView.Socket.t(), id :: String.t(), kind :: atom(), rows :: list()) ::
              Phoenix.LiveView.Socket.t() | nil

  @doc "Whether the chart is drawn by the server, in the page's HTML."
  @callback server_drawn?() :: boolean()

  @libs %{
    "fude" => Bench.Libs.Fude,
    "vega_lite" => Bench.Libs.VegaLite,
    "contex" => Bench.Libs.Contex,
    "live_charts" => Bench.Libs.LiveCharts
  }

  def all, do: @libs
  def keys, do: ~w(fude vega_lite contex live_charts)
  def fetch(key), do: Map.fetch(@libs, key)

  def version(lib) do
    lib.package() |> Application.spec(:vsn) |> to_string()
  end
end
