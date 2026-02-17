defmodule GlossaryWeb.TopicLive.Index do
  use GlossaryWeb, :live_view

  alias Glossary.Topics

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "All Topics")
     |> stream(:topics, Topics.list_topics())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    topic = Topics.get_topic!(id)
    {:ok, _} = Topics.delete_topic(topic)

    {:noreply, stream_delete(socket, :topics, topic)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.live_component
        module={GlossaryWeb.SearchModal}
        id="global-search-modal"
      />

      <LiveLayouts.back_link navigate={~p"/"} text="Back to Dashboard" />

      <div class="space-y-2">
        <.header>
          All Topics
          <:actions>
            <.button variant="primary" navigate={~p"/topics/new"}>
              <.icon name="hero-plus" /> New Topic
            </.button>
          </:actions>
        </.header>

        <.table
          id="topics"
          rows={@streams.topics}
          row_click={fn {_id, topic} -> JS.navigate(~p"/topics/#{topic}") end}
        >
          <:col :let={{_id, topic}} label="Name">
            <span class="font-semibold">{topic.name}</span>
          </:col>
          <:action :let={{_id, topic}}>
            <.link
              href="#"
              phx-click="delete"
              phx-value-id={topic.id}
              data-confirm="Are you sure you want to delete this topic?"
            >
              Delete
            </.link>
          </:action>
          <:action :let={{_id, topic}}>
            <.link navigate={~p"/topics/#{topic}"}>View</.link>
          </:action>
        </.table>
      </div>
    </Layouts.app>
    """
  end
end
