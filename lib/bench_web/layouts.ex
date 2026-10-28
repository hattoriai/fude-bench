defmodule BenchWeb.Layouts do
  @moduledoc """
  The root layout: only the chosen library's files, Phoenix and LiveView,
  and `mark/2`, which records when a chart is drawn or updated: after the
  next frame, so that the time includes the browser's paint.
  """
  use Phoenix.Component

  def root(assigns) do
    lib =
      case Bench.Lib.fetch(assigns.conn.path_params["lib"] || "") do
        {:ok, lib} -> lib
        :error -> nil
      end

    assigns = assign(assigns, lib: lib, assets: if(lib, do: lib.assets(), else: []))

    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
        <title>fude-bench</title>
        <script>
          window.__bench = { drawn: [], updated: [], connected: null }
          window.mark = (kind, id) =>
            requestAnimationFrame(() => setTimeout(() => window.__bench[kind].push({ id, t: performance.now() })))
        </script>
        <link :for={{:css, url, _} <- @assets} rel="stylesheet" href={url} />
        <script :for={{:js, url, _} <- @assets} src={url}>
        </script>
        <style>
          body { font-family: system-ui, sans-serif; margin: 16px; background: #fff; color: #222; }
          .grid { display: grid; grid-template-columns: repeat(3, 320px); gap: 16px; }
          button { font: inherit; margin-bottom: 16px; }
        </style>
        <script type="importmap">
          {"imports": {"phoenix": "/vendor/phoenix/phoenix.mjs", "phoenix_live_view": "/vendor/phoenix_live_view/phoenix_live_view.esm.js"}}
        </script>
        <script type="module">
          import { Socket } from "phoenix"
          import { LiveSocket } from "phoenix_live_view"
          const mark = window.mark
          const hooks = {}
          <%= Phoenix.HTML.raw(if @lib, do: @lib.hooks(), else: "") %>
          window.addEventListener("phx:page-loading-stop", () => { window.__bench.connected ??= performance.now() })
          const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
          const liveSocket = new LiveSocket("/live", Socket, { hooks, params: { _csrf_token: csrfToken } })
          liveSocket.connect()
          window.liveSocket = liveSocket
        </script>
      </head>
      <body>
        {@inner_content}
      </body>
    </html>
    """
  end
end
