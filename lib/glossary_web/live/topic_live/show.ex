defmodule GlossaryWeb.TopicLive.Show do
  use GlossaryWeb, :live_view

  alias Glossary.Entries
  alias Glossary.Topics

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    topic = Topics.get_topic!(id)

    {:ok,
     socket
     |> assign(:page_title, topic.name)
     |> assign(:topic, topic)
     |> assign(:entry_search_query, "")
     |> assign(:available_entries, [])
     |> assign(:show_entry_picker?, false)
     |> stream(:topic_entries, topic.entries)}
  end

  @impl true
  def handle_event("show_entry_picker", _params, socket) do
    available = Topics.available_entries(socket.assigns.topic)

    {:noreply,
     socket
     |> assign(:show_entry_picker?, true)
     |> assign(:available_entries, available)
     |> assign(:entry_search_query, "")}
  end

  @impl true
  def handle_event("hide_entry_picker", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_entry_picker?, false)
     |> assign(:available_entries, [])
     |> assign(:entry_search_query, "")}
  end

  @impl true
  def handle_event("search_entries", %{"query" => query}, socket) do
    available = Topics.available_entries(socket.assigns.topic, query)

    {:noreply,
     socket
     |> assign(:entry_search_query, query)
     |> assign(:available_entries, available)}
  end

  @impl true
  def handle_event("add_entry", %{"id" => entry_id}, socket) do
    entry = Entries.get_entry!(entry_id)
    {:ok, topic} = Topics.add_entry(socket.assigns.topic, entry)

    available = Topics.available_entries(topic, socket.assigns.entry_search_query)

    {:noreply,
     socket
     |> assign(:topic, topic)
     |> assign(:available_entries, available)
     |> stream_insert(:topic_entries, entry)}
  end

  @impl true
  def handle_event("remove_entry", %{"id" => entry_id}, socket) do
    entry = Entries.get_entry!(entry_id)
    {:ok, topic} = Topics.remove_entry(socket.assigns.topic, entry)

    available =
      if socket.assigns.show_entry_picker? do
        Topics.available_entries(topic, socket.assigns.entry_search_query)
      else
        []
      end

    {:noreply,
     socket
     |> assign(:topic, topic)
     |> assign(:available_entries, available)
     |> stream_delete(:topic_entries, entry)}
  end

  @impl true
  def handle_info({:search_modal_action, level, message}, socket) do
    topic = Topics.get_topic!(socket.assigns.topic.id)

    {:noreply,
     socket
     |> put_flash(level, message)
     |> assign(:topic, topic)
     |> stream(:topic_entries, topic.entries, reset: true)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.live_component
        module={GlossaryWeb.SearchModal}
        id="global-search-modal"
        context={%{page: :topic_show, topic: @topic}}
      />

      <LiveLayouts.back_link navigate={~p"/topics"} text="Back to Topics" />

      <div class="space-y-6">
        <.header>
          {@topic.name}
          <:actions>
            <.button variant="primary" navigate={~p"/topics/#{@topic}/edit"}>
              <.icon name="hero-pencil-square" /> Edit
            </.button>
          </:actions>
        </.header>

        <section class="space-y-2">
          <div class="flex items-center justify-between">
            <h2 class="text-lg font-semibold">Entries</h2>
            <.button
              :if={!@show_entry_picker?}
              id="show-entry-picker-button"
              phx-click="show_entry_picker"
            >
              <.icon name="hero-plus" /> Add Entry
            </.button>
          </div>

          <%!-- Entry picker --%>
          <div
            :if={@show_entry_picker?}
            id="entry-picker"
            class="border-base-300 bg-base-100 space-y-3 rounded-lg border p-4"
          >
            <div class="flex items-center justify-between">
              <h3 class="font-medium">Add entries to this topic</h3>
              <button
                id="hide-entry-picker-button"
                phx-click="hide_entry_picker"
                type="button"
                class="btn btn-ghost btn-sm"
              >
                <.icon name="hero-x-mark" class="size-4" />
              </button>
            </div>

            <.form
              for={%{}}
              id="entry-search-form"
              phx-change="search_entries"
              class="w-full"
            >
              <.input
                id="entry-search-input"
                type="text"
                name="query"
                placeholder="Search entries..."
                autocomplete="off"
                value={@entry_search_query}
                phx-debounce="150"
                class="w-full"
              />
            </.form>

            <div class="max-h-60 space-y-1 overflow-y-auto">
              <div
                :if={@available_entries == []}
                class="text-base-content/50 py-4 text-center text-sm"
              >
                No available entries found.
              </div>
              <button
                :for={entry <- @available_entries}
                id={"available-entry-#{entry.id}"}
                phx-click="add_entry"
                phx-value-id={entry.id}
                type="button"
                class="flex w-full items-center gap-2 rounded-lg p-2 text-left hover:bg-base-200"
              >
                <.icon name="hero-plus-circle" class="size-5 text-success shrink-0" />
                <div>
                  <div class="font-medium">
                    <%= if entry.title_text && entry.title_text != "" do %>
                      {entry.title_text}
                    <% else %>
                      <em class="text-base-content/25 italic">No Title</em>
                    <% end %>
                  </div>
                  <div
                    :if={entry.subtitle_text && entry.subtitle_text != ""}
                    class="text-base-content/50 text-sm"
                  >
                    {entry.subtitle_text}
                  </div>
                </div>
              </button>
            </div>
          </div>

          <%!-- Topic entries table --%>
          <.table id="topic-entries" rows={@streams.topic_entries}>
            <:col :let={{_id, entry}} label="Title">
              <%= if !entry.title_text || entry.title_text == "" do %>
                <em class="text-base-content/25 italic">No Title</em>
              <% else %>
                <span class="font-semibold">{entry.title_text}</span>
              <% end %>
            </:col>
            <:col :let={{_id, entry}} label="Subtitle">
              <%= if !entry.subtitle_text || entry.subtitle_text == "" do %>
                <em class="text-base-content/25 italic">No Subtitle</em>
              <% else %>
                <span class="text-base-content/50 text-sm">{entry.subtitle_text}</span>
              <% end %>
            </:col>
            <:action :let={{_id, entry}}>
              <.link
                href="#"
                phx-click="remove_entry"
                phx-value-id={entry.id}
                data-confirm="Remove this entry from the topic?"
              >
                Remove
              </.link>
            </:action>
            <:action :let={{_id, entry}}>
              <.link navigate={~p"/entries/#{entry}"}>View</.link>
            </:action>
          </.table>
        </section>
      </div>
    </Layouts.app>
    """
  end
end
