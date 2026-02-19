defmodule GlossaryWeb.TagLive.Index do
  use GlossaryWeb, :live_view

  alias Glossary.Tags

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "All Tags")
     |> stream(:tags, Tags.list_tags(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    tag = Tags.get_tag!(socket.assigns.current_scope, id)
    {:ok, _} = Tags.delete_tag(socket.assigns.current_scope, tag)

    {:noreply, stream_delete(socket, :tags, tag)}
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
          All Tags
          <:actions>
            <.button variant="primary" navigate={~p"/tags/new"}>
              <.icon name="hero-plus" /> New Tag
            </.button>
          </:actions>
        </.header>

        <.table
          id="tags"
          rows={@streams.tags}
          row_click={fn {_id, tag} -> JS.navigate(~p"/tags/#{tag}") end}
        >
          <:col :let={{_id, tag}} label="Name">
            <span class="font-semibold">{tag.name}</span>
          </:col>
          <:action :let={{_id, tag}}>
            <.link
              href="#"
              phx-click="delete"
              phx-value-id={tag.id}
              data-confirm="Are you sure you want to delete this tag?"
            >
              Delete
            </.link>
          </:action>
          <:action :let={{_id, tag}}>
            <.link navigate={~p"/tags/#{tag}"}>View</.link>
          </:action>
        </.table>
      </div>
    </Layouts.app>
    """
  end
end
