defmodule GlossaryWeb.ProjectLive.Edit do
  use GlossaryWeb, :live_view

  alias Glossary.Projects

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    project = Projects.get_project!(id)
    changeset = Projects.change_project(project)

    {:ok,
     socket
     |> assign(:page_title, "Edit Project")
     |> assign(:project, project)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate", %{"project" => project_params}, socket) do
    changeset =
      socket.assigns.project
      |> Projects.change_project(project_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"project" => project_params}, socket) do
    case Projects.update_project(socket.assigns.project, project_params) do
      {:ok, project} ->
        {:noreply,
         socket
         |> put_flash(:info, "Project updated successfully.")
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
        Edit Project
        <:subtitle>Update the project name.</:subtitle>
      </.header>

      <.form for={@form} id="project-form" phx-change="validate" phx-submit="save" class="mt-6">
        <.input field={@form[:name]} type="text" label="Name" />

        <div class="mt-6 flex items-center gap-4">
          <.button variant="primary" phx-disable-with="Saving...">Save Changes</.button>
          <.link navigate={~p"/projects/#{@project}"} class="text-sm">Cancel</.link>
        </div>
      </.form>
    </Layouts.app>
    """
  end
end
