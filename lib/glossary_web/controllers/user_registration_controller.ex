defmodule GlossaryWeb.UserRegistrationController do
  use GlossaryWeb, :controller

  alias Glossary.Accounts
  alias Glossary.Accounts.User

  def new(conn, _params) do
    changeset = Accounts.change_user_email(%User{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, _user} ->
        # Email sending disabled
        conn
        |> put_flash(
          :info,
          "Account created successfully. Please log in."
        )
        |> redirect(to: ~p"/users/log-in")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end
end
