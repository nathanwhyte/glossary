defmodule GlossaryWeb.ProjectLive.New do
  use GlossaryWeb, :live_view

  alias Glossary.Projects
  alias Glossary.Projects.Project

  @impl true
  def mount(_params, _session, socket) do
    changeset = Projects.change_project(%Project{})

    {:ok,
     socket
     |> assign(:page_title, "New Project")
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate", %{"project" => project_params}, socket) do
    changeset =
      %Project{}
      |> Projects.change_project(project_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"project" => project_params}, socket) do
    case Projects.create_project(project_params) do
      {:ok, project} ->
        {:noreply,
         socket
         |> put_flash(:info, "Project created successfully.")
         |> push_navigate(to: ~p"/projects/#{project}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.live_component
        module={GlossaryWeb.SearchModal}
        id="global-search-modal"
      />

      <LiveLayouts.back_link navigate={~p"/projects"} text="Back to Projects" />

      <.header>
        New Project
        <:subtitle>Create a new project to group entries.</:subtitle>
      </.header>

      <.form for={@form} id="project-form" phx-change="validate" phx-submit="save" class="mt-6">
        <.input field={@form[:name]} type="text" label="Name" />

        <div class="mt-6 flex items-center gap-4">
          <.button variant="primary" phx-disable-with="Creating...">Create Project</.button>
          <.link navigate={~p"/projects"} class="text-sm">Cancel</.link>
        </div>
      </.form>
    </Layouts.app>
    """
  end
end
