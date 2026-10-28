defmodule BenchWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :bench

  @session [store: :cookie, key: "_bench", signing_salt: "fude-bench"]

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session]])

  plug(BenchWeb.Assets)
  plug(Plug.Static, at: "/vendor/phoenix", from: {:phoenix, "priv/static"})
  plug(Plug.Static, at: "/vendor/phoenix_live_view", from: {:phoenix_live_view, "priv/static"})
  plug(Plug.Session, @session)
  plug(BenchWeb.Router)
end

defmodule BenchWeb.ErrorHTML do
  def render(template, _assigns), do: Phoenix.Controller.status_message_from_template(template)
end
