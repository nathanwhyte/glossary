defmodule GlossaryWeb.TagLive.New do
  use GlossaryWeb, :live_view

  alias Glossary.Tags
  alias Glossary.Tags.Tag

  @impl true
  def mount(_params, _session, socket) do
    changeset = Tags.change_tag(%Tag{})

    {:ok,
     socket
     |> assign(:page_title, "New Tag")
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate", %{"tag" => tag_params}, socket) do
    changeset =
      %Tag{}
      |> Tags.change_tag(tag_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"tag" => tag_params}, socket) do
    case Tags.create_tag(socket.assigns.current_scope, tag_params) do
      {:ok, tag} ->
        {:noreply,
         socket
         |> put_flash(:info, "Tag created successfully.")
         |> push_navigate(to: ~p"/tags/#{tag}")}

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
        current_scope={@current_scope}
      />

      <LiveLayouts.back_link navigate={~p"/tags"} text="Back to Tags" />

      <.header>
        New Tag
        <:subtitle>Create a new tag to label entries and projects.</:subtitle>
      </.header>

      <.form for={@form} id="tag-form" phx-change="validate" phx-submit="save" class="mt-6">
        <.input field={@form[:name]} type="text" label="Name" />

        <div class="mt-6 flex items-center gap-4">
          <.button variant="primary" phx-disable-with="Creating...">Create Tag</.button>
          <.link navigate={~p"/tags"} class="text-sm">Cancel</.link>
        </div>
      </.form>
    </Layouts.app>
    """
  end
end
