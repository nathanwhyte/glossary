defmodule GlossaryWeb.EntryLive.Edit do
  use GlossaryWeb, :live_view

  alias Glossary.Entries
  alias Glossary.Entries.Entry

  @impl true
  def mount(params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("title_update", %{"title" => title, "title_text" => title_text}, socket) do
    {:noreply, save_field(socket, %{title: title, title_text: title_text})}
  end

  @impl true
  def handle_event(
        "subtitle_update",
        %{"subtitle" => subtitle, "subtitle_text" => subtitle_text},
        socket
      ) do
    {:noreply, save_field(socket, %{subtitle: subtitle, subtitle_text: subtitle_text})}
  end

  @impl true
  def handle_event("body_update", %{"body" => body, "body_text" => body_text}, socket) do
    {:noreply, save_field(socket, %{body: body, body_text: body_text})}
  end

  defp save_field(socket, attrs) do
    entry = socket.assigns.entry

    case Entries.upsert_entry(socket.assigns.current_scope, entry, attrs) do
      {:ok, entry} -> assign(socket, :entry, entry)
      {:error, _changeset} -> socket
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.live_component
        module={GlossaryWeb.SearchModal}
        id="global-search-modal"
        current_scope={@current_scope}
        context={%{page: :entry_edit, entry: @entry}}
      />

      <div>
        <LiveLayouts.back_link navigate={~p"/entries"} text="Back to Entries" />

        <div class="mt-4 flex items-center justify-between">
          <div
            id="title-editor"
            phx-hook="TitleEditor"
            data-value={@entry.title}
          >
            <div data-editor="title" id="entry-title" phx-update="ignore" class="title-editor" />
          </div>

          <%!-- IDEA: entry actions menu --%>
          <div>
            <.icon name="hero-ellipsis-vertical-micro" class="size-6 text-base-content/50" />
          </div>
        </div>

        <div
          id="subtitle-editor"
          phx-hook="SubtitleEditor"
          data-value={@entry.subtitle}
          class="mt-1"
        >
          <div data-editor="subtitle" id="entry-subtitle" phx-update="ignore" class="subtitle-editor" />
        </div>
      </div>

      <div class="divider" />

      <div class="mt-4">
        <div
          id="body-editor"
          phx-hook="BodyEditor"
          data-value={@entry.body}
          class="mt-2"
        >
          <div data-editor="body" id="entry-body" phx-update="ignore" class="body-editor" />
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_info({:search_modal_action, level, message}, socket) do
    {:noreply, put_flash(socket, level, message)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    entry = Entries.get_entry!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Entry")
    |> assign(:entry, entry)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Entry")
    |> assign(:entry, %Entry{})
  end
end
