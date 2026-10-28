defmodule BenchWeb.ChartLive do
  @moduledoc """
  A page of one library: one chart of a case (`/chart/:lib/:case`) or the
  dashboard of twelve small charts (`/dashboard/:lib`). The button gives
  every chart new data of the same shape.
  """
  use Phoenix.LiveView

  @large {640, 320}
  @small {320, 180}

  @impl true
  def mount(%{"lib" => key} = params, _session, socket) do
    {:ok, lib} = Bench.Lib.fetch(key)
    kase = params["case"] && String.to_existing_atom(params["case"])
    {:ok, assign(socket, lib: lib, case: kase, seed: 0, charts: charts(kase, 0))}
  end

  @impl true
  def handle_event("update", _params, socket) do
    %{lib: lib, case: kase, seed: seed} = socket.assigns
    seed = seed + 1
    charts = charts(kase, seed)

    pushed =
      Enum.reduce_while(charts, socket, fn chart, acc ->
        case lib.push(acc, chart.id, chart.kind, chart.rows) do
          nil -> {:halt, nil}
          acc -> {:cont, acc}
        end
      end)

    # A library that takes new data by an event keeps its render as it was.
    socket = if pushed, do: assign(pushed, :seed, seed), else: assign(socket, seed: seed, charts: charts)
    {:noreply, socket}
  end

  defp charts(nil, seed) do
    {width, height} = @small

    for {id, kind, rows} <- Bench.Data.dashboard(seed),
        do: %{id: id, kind: kind, rows: rows, width: width, height: height}
  end

  defp charts(kase, seed) do
    {width, height} = @large
    [%{id: "chart", kind: kase, rows: Bench.Data.rows(kase, :large, seed), width: width, height: height}]
  end

  @impl true
  def render(assigns) do
    ~H"""
    <button id="update" phx-click="update">Update data</button>
    <div class={@case == nil && "grid"}>
      <div :for={chart <- @charts}>
        {@lib.chart(Map.put(chart, :__changed__, nil))}
      </div>
    </div>
    """
  end
end

defmodule BenchWeb.IndexLive do
  use Phoenix.LiveView

  @impl true
  def render(assigns) do
    assigns = assign(assigns, libs: Bench.Lib.keys(), cases: Bench.Data.cases())

    ~H"""
    <h1>fude-bench</h1>
    <table>
      <tr :for={lib <- @libs}>
        <th>{lib}</th>
        <td :for={kase <- @cases}><a href={"/chart/#{lib}/#{kase}"}>{kase}</a></td>
        <td><a href={"/dashboard/#{lib}"}>dashboard</a></td>
      </tr>
    </table>
    """
  end
end
