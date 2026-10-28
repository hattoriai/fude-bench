defmodule Bench.Data do
  @moduledoc """
  The data of each case: made up, the same on every run for a seed. A new
  seed gives the same shape with new values (the update of a page).

  Every library gets the same rows; each library module reshapes them the
  way its documentation asks (columns, series, wide rows).
  """

  @groups ["Alpha", "Beta", "Gamma"]
  @series ["North", "South", "East", "West"]

  @cases ~w(scatter lines bars)a

  @doc "The cases of a single chart."
  def cases, do: @cases

  # A number in [0, 1) from a term: the same on every run.
  defp noise(term), do: :erlang.phash2(term, 1_000_000) / 1_000_000

  @doc """
  The rows of a case, at a size: `:scatter` points (x, y, group), `:lines`
  days of four series (date, series, value), `:bars` categories (name,
  value).
  """
  def rows(kind, size \\ :large, seed \\ 0)

  def rows(:scatter, size, seed) do
    n = if size == :large, do: 1000, else: 150

    for i <- 1..n do
      g = rem(i, 3)
      x = 10 + 80 * noise({seed, :x, i})
      y = 5 + 0.6 * x + 25 * noise({seed, :y, i}) + g * 12

      %{x: Float.round(x, 2), y: Float.round(y, 2), group: Enum.at(@groups, g)}
    end
  end

  def rows(:lines, size, seed) do
    days = if size == :large, do: 1000, else: 90
    series = if size == :large, do: @series, else: Enum.take(@series, 2)

    for {name, s} <- Enum.with_index(series),
        {day, i} <- Enum.with_index(Date.range(~D[2023-01-01], Date.add(~D[2023-01-01], days - 1))) do
      trend = 100 + s * 40 + i * 0.05 * (s + 1)
      season = 15 * :math.sin(i / 58 + s)
      %{date: day, series: name, value: Float.round(trend + season + 20 * noise({seed, s, i}), 1)}
    end
  end

  def rows(:bars, size, seed) do
    n = if size == :large, do: 200, else: 12

    for i <- 1..n do
      %{
        name: "Item #{String.pad_leading(Integer.to_string(i), 3, "0")}",
        value: round(10 + 90 * noise({seed, :bar, i}))
      }
    end
  end

  @doc """
  The charts of the dashboard: twelve small charts, four of each kind, as
  `{id, kind, rows}`.
  """
  def dashboard(seed \\ 0) do
    for {kind, k} <- Enum.with_index(@cases), i <- 1..4 do
      {"#{kind}-#{i}", kind, rows(kind, :small, seed * 100 + k * 10 + i)}
    end
  end
end
