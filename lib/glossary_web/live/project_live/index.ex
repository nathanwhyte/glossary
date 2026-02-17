defmodule GlossaryWeb.ProjectLive.Index do
  use GlossaryWeb, :live_view

  alias Glossary.Projects

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "All Projects")
     |> stream(:projects, Projects.list_projects())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    project = Projects.get_project!(id)
    {:ok, _} = Projects.delete_project(project)

    {:noreply, stream_delete(socket, :projects, project)}
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
          All Projects
          <:actions>
            <.button variant="primary" navigate={~p"/projects/new"}>
              <.icon name="hero-plus" /> New Project
            </.button>
          </:actions>
        </.header>

        <.table
          id="projects"
          rows={@streams.projects}
          row_click={fn {_id, project} -> JS.navigate(~p"/projects/#{project}") end}
        >
          <:col :let={{_id, project}} label="Name">
            <span class="font-semibold">{project.name}</span>
          </:col>
          <:action :let={{_id, project}}>
            <.link
              href="#"
              phx-click="delete"
              phx-value-id={project.id}
              data-confirm="Are you sure you want to delete this project?"
            >
              Delete
            </.link>
          </:action>
          <:action :let={{_id, project}}>
            <.link navigate={~p"/projects/#{project}"}>View</.link>
          </:action>
        </.table>
      </div>
    </Layouts.app>
    """
  end
end
