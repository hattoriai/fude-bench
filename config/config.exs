import Config

config :phoenix, :json_library, Jason
config :live_charts, adapter: LiveCharts.Adapter.ApexCharts, json_library: Jason
config :logger, level: :warning

config :bench, BenchWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  http: [ip: {127, 0, 0, 1}, port: 4200],
  url: [host: "localhost"],
  check_origin: false,
  server: true,
  secret_key_base: String.duplicate("fude-bench-secret-key-base-", 3),
  live_view: [signing_salt: "fude-bench-salt"],
  pubsub_server: Bench.PubSub,
  render_errors: [formats: [html: BenchWeb.ErrorHTML], layout: false]
