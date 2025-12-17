defmodule GlossaryWeb.HealthController do
  use GlossaryWeb, :controller

  @doc """
  Liveness probe endpoint - checks if the application is running.
  Does not check database connectivity, as we don't want to restart
  the pod if the database is temporarily unavailable.
  """
  def liveness(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{status: "ok"})
  end

  @doc """
  Readiness probe endpoint - checks if the application is ready to serve traffic.
  This includes checking database connectivity.
  """
  def readiness(conn, _params) do
    case check_database() do
      :ok ->
        conn
        |> put_status(:ok)
        |> json(%{status: "ready", database: "connected"})

      {:error, reason} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{status: "not_ready", database: "disconnected", reason: inspect(reason)})
    end
  end

  defp check_database do
    try do
      case Glossary.Repo.query("SELECT 1", []) do
        {:ok, _} -> :ok
        {:error, error} -> {:error, error}
      end
    rescue
      e -> {:error, e}
    end
  end
end
