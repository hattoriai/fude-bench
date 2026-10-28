defmodule Mix.Tasks.Bench do
  @shortdoc "Measures every library on the server and in the browser; writes results/"
  @moduledoc """
  Measures every library: on the server (`Bench.Server`), then in a browser
  with Playwright (`browser/run.mjs`) against the pages of this app, and
  writes `results/server.json`, `results/browser.json` and
  `results/REPORT.md`.

      mix bench [--runs 7] [--browsers chromium,firefox,webkit] [--libs fude,contex] [--server-only]
  """
  use Mix.Task

  @impl true
  def run(args) do
    {opts, _} =
      OptionParser.parse!(args, strict: [runs: :integer, browsers: :string, libs: :string, server_only: :boolean])

    Mix.Task.run("compile")
    Bench.Server.start()
    File.mkdir_p!("results")

    Mix.shell().info("Server: build and render each chart…")
    server = %{charts: Bench.Server.measure(), assets: Bench.Server.assets(), env: env()}
    File.write!("results/server.json", Jason.encode!(server, pretty: true))

    browser =
      if opts[:server_only] do
        nil
      else
        Mix.shell().info("Browser: load and update each page…")

        node_args =
          ["run.mjs", "--out", "../results/browser.json", "--runs", to_string(opts[:runs] || 7)] ++
            if(opts[:browsers], do: ["--browsers", opts[:browsers]], else: []) ++
            if(opts[:libs], do: ["--libs", opts[:libs]], else: [])

        {_, 0} = System.cmd("node", node_args, cd: "browser", into: IO.stream(:stdio, :line))
        "results/browser.json" |> File.read!() |> Jason.decode!()
      end

    File.write!("results/REPORT.md", Bench.Report.markdown(server, browser))
    Mix.shell().info("Wrote results/REPORT.md")
  end

  # Hex, or the commit of the checkout FUDE_PATH points at.
  defp fude_source do
    case System.get_env("FUDE_PATH") do
      nil ->
        "Hex #{Application.spec(:fude, :vsn)}"

      path ->
        {sha, _} = System.cmd("git", ["rev-parse", "--short", "HEAD"], cd: path)
        "checkout at #{String.trim(sha)}"
    end
  end

  defp env do
    %{
      elixir: System.version(),
      otp: System.otp_release(),
      date: Date.utc_today(),
      system: :erlang.system_info(:system_architecture) |> to_string(),
      schedulers: System.schedulers_online(),
      fude: fude_source()
    }
  end
end
