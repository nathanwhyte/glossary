defmodule GlossaryWeb.KeybindMacrosTest do
  use GlossaryWeb.LiveCase

  describe "pubsub_broadcast_on_event/4 macro" do
    test "generates handle_event that broadcasts correct topic", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      Phoenix.PubSub.subscribe(Glossary.PubSub, "search_modal")

      render_hook(view, "summon_modal", %{})
      assert_receive {:summon_modal, true}
    end

    test "generates handle_event that broadcasts correct payload", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      Phoenix.PubSub.subscribe(Glossary.PubSub, "search_modal")

      render_hook(view, "banish_modal", %{})
      assert_receive {:summon_modal, false}
    end
  end

  describe "keybind_listeners/0 macro" do
    test "leader key state management (Meta)", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      simulate_keydown(view, "Meta")
      # State is internal, verify via behavior: k should work after Meta
      Phoenix.PubSub.subscribe(Glossary.PubSub, "search_modal")
      simulate_keydown(view, "k")
      assert_receive {:summon_modal, true}
    end

    test "leader key state management (Control)", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      simulate_keydown(view, "Control")
      # State is internal, verify via behavior: k should work after Control
      Phoenix.PubSub.subscribe(Glossary.PubSub, "search_modal")
      simulate_keydown(view, "k")
      assert_receive {:summon_modal, true}
    end

    test "k key respects leader key guard", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      Phoenix.PubSub.subscribe(Glossary.PubSub, "search_modal")
      simulate_keydown(view, "k")
      refute_receive {:summon_modal, true}, 50
    end

    test "k key broadcasts when leader is down", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      Phoenix.PubSub.subscribe(Glossary.PubSub, "search_modal")
      simulate_keydown(view, "Meta")
      simulate_keydown(view, "k")
      assert_receive {:summon_modal, true}
    end

    test "Escape broadcasts regardless of leader state", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      Phoenix.PubSub.subscribe(Glossary.PubSub, "search_modal")
      simulate_keydown(view, "Escape")
      assert_receive {:summon_modal, false}
    end

    test "o key respects leader + shift guards", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      simulate_keydown(view, "Meta")
      simulate_keydown(view, "o")
      # Should not navigate
      assert view.module == GlossaryWeb.HomeLive
    end

    test "o key with Shift creates entry and navigates", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      simulate_keydown(view, "Meta")
      simulate_keydown(view, "Shift")

      assert {:error, {:live_redirect, %{kind: :push, to: redirect_to}}} =
               simulate_keydown(view, "o")

      assert redirect_to =~ ~r|/entries/[a-f0-9-]{36}|
    end

    test "key_up resets leader state", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      simulate_keydown(view, "Meta")
      simulate_keyup(view, "Meta")
      # Verify by testing that k doesn't work after key_up
      Phoenix.PubSub.subscribe(Glossary.PubSub, "search_modal")
      simulate_keydown(view, "k")
      refute_receive {:summon_modal, true}, 50
    end

    test "unknown keys don't crash", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      simulate_keydown(view, "UnknownKey")
      assert true
    end
  end
end
