defmodule GlossaryWeb.Plugs.HealthCheck do
  import Plug.Conn

  @moduledoc """
  Plug that returns a plain-text OK response for `/health` requests.
  """

  def init(opts), do: opts

  def call(%Plug.Conn{request_path: "/health"} = conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "ok")
    |> halt()
  end

  def call(conn, _opts), do: conn
end
