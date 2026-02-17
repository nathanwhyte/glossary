defmodule GlossaryWeb.UserLive.RegistrationTest do
  use GlossaryWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Glossary.AccountsFixtures

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register")

      assert html =~ "Register"
      assert html =~ "Log in"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/register")
        |> follow_redirect(conn, ~p"/")

      assert {:ok, _conn} = result
    end

    test "renders errors for invalid username", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"username" => "bad user!"})

      assert result =~ "can only contain letters, numbers, and underscores"
    end
  end

  describe "register user" do
    test "creates account and redirects to login", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      username = unique_user_username()
      password = valid_user_password()

      form =
        form(lv, "#registration_form",
          user: %{username: username, password: password, password_confirmation: password}
        )

      {:ok, _lv, html} =
        render_submit(form)
        |> follow_redirect(conn, ~p"/users/log-in")

      assert html =~ "Account created successfully"
    end

    test "renders errors for duplicated username", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      user = user_fixture()

      result =
        lv
        |> form("#registration_form",
          user: %{
            "username" => user.username,
            "password" => valid_user_password(),
            "password_confirmation" => valid_user_password()
          }
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      {:ok, _login_live, login_html} =
        lv
        |> element("main a", "Log in")
        |> render_click()
        |> follow_redirect(conn, ~p"/users/log-in")

      assert login_html =~ "Log in"
    end
  end
end
