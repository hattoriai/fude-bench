defmodule BenchWeb.Assets do
  @moduledoc "Serves the files of each library (`Bench.Lib.assets/0`) at their URLs."
  @behaviour Plug
  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(%Plug.Conn{request_path: "/libs/" <> _ = path} = conn, _opts) do
    found =
      Enum.find_value(Bench.Lib.all(), fn {_, lib} ->
        Enum.find_value(lib.assets(), fn {type, url, file} -> url == path && {type, file} end)
      end)

    case found do
      {type, file} ->
        conn
        |> put_resp_content_type(if(type == :css, do: "text/css", else: "text/javascript"))
        |> put_resp_header("cache-control", "no-store")
        |> send_file(200, file)
        |> halt()

      nil ->
        conn |> send_resp(404, "not found") |> halt()
    end
  end

  def call(conn, _opts), do: conn
end
