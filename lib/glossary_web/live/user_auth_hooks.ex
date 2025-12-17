defmodule GlossaryWeb.UserAuthHooks do
  @moduledoc """
  LiveView hooks for authentication.

  These hooks align with Phoenix's phx.gen.auth pattern using `current_scope`.
  The `fetch_current_scope_for_user` plug in the browser pipeline sets
  `conn.assigns.current_scope`, and these hooks make it available to LiveViews.
  """
  import Phoenix.LiveView
  import Phoenix.Component
  use GlossaryWeb, :verified_routes

  alias Glossary.Accounts.Scope

  def on_mount(:ensure_authenticated, _params, session, socket) do
    scope = get_scope_from_session(session)

    if scope && scope.user do
      {:cont, assign(socket, :current_scope, scope)}
    else
      socket =
        socket
        |> put_flash(:error, "You must log in to access this page.")
        |> redirect(to: ~p"/users/log-in")

      {:halt, socket}
    end
  end

  def on_mount(:assign_current_scope, _params, session, socket) do
    scope = get_scope_from_session(session)
    {:cont, assign(socket, :current_scope, scope)}
  end

  defp get_scope_from_session(session) do
    # Session can have either atom or string keys
    token = Map.get(session, :user_token) || Map.get(session, "user_token")

    case token do
      nil ->
        Scope.for_user(nil)

      token ->
        case Glossary.Accounts.get_user_by_session_token(token) do
          {user, _token_inserted_at} -> Scope.for_user(user)
          nil -> Scope.for_user(nil)
        end
    end
  end
end
