defmodule BenchWeb.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_root_layout, html: {BenchWeb.Layouts, :root})
  end

  scope "/" do
    pipe_through(:browser)

    live("/", BenchWeb.IndexLive)
    live("/chart/:lib/:case", BenchWeb.ChartLive)
    live("/dashboard/:lib", BenchWeb.ChartLive)
  end
end
