defmodule GlossaryWeb.TopicLive.Index do
  use GlossaryWeb, :live_view

  alias Glossary.Topics

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id
    if connected?(socket), do: Phoenix.PubSub.subscribe(Glossary.PubSub, "user_topics:#{user_id}")

    {:ok,
     socket
     |> assign(:page_title, "All Topics")
     |> stream(:topics, Topics.list_topics(socket.assigns.current_scope))}
  end

  @impl true
  def handle_info({event, topic_id}, socket) when event in [:topic_created, :topic_updated] do
    topic = Topics.get_topic!(socket.assigns.current_scope, topic_id)

    {:noreply,
     stream_insert(socket, :topics, topic, at: if(event == :topic_created, do: 0, else: -1))}
  end

  @impl true
  def handle_info({:topic_deleted, topic_id}, socket) do
    {:noreply, stream_delete(socket, :topics, %Topics.Topic{id: topic_id})}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    topic = Topics.get_topic!(socket.assigns.current_scope, id)
    {:ok, _} = Topics.delete_topic(socket.assigns.current_scope, topic)

    {:noreply, stream_delete(socket, :topics, topic)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.live_component
        module={GlossaryWeb.SearchModal}
        id="global-search-modal"
        current_scope={@current_scope}
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
