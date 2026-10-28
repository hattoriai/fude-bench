defmodule Mix.Tasks.Bench.Serve do
  @shortdoc "Serves the pages of the benchmark at http://localhost:4200"
  @moduledoc "Serves the pages, to look at each library's charts: `mix bench.serve`."
  use Mix.Task

  @impl true
  def run(_args) do
    Mix.Task.run("compile")
    Bench.Server.start()
    Mix.shell().info("http://localhost:4200")
    Process.sleep(:infinity)
  end
end
