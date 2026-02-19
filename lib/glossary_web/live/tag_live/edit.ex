defmodule GlossaryWeb.TagLive.Edit do
  use GlossaryWeb, :live_view

  alias Glossary.Tags

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    tag = Tags.get_tag!(socket.assigns.current_scope, id)
    changeset = Tags.change_tag(tag)

    {:ok,
     socket
     |> assign(:page_title, "Edit Tag")
     |> assign(:tag, tag)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate", %{"tag" => tag_params}, socket) do
    changeset =
      socket.assigns.tag
      |> Tags.change_tag(tag_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"tag" => tag_params}, socket) do
    case Tags.update_tag(socket.assigns.current_scope, socket.assigns.tag, tag_params) do
      {:ok, tag} ->
        {:noreply,
         socket
         |> put_flash(:info, "Tag updated successfully.")
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
        Edit Tag
        <:subtitle>Update the tag name.</:subtitle>
      </.header>

      <.form for={@form} id="tag-form" phx-change="validate" phx-submit="save" class="mt-6">
        <.input field={@form[:name]} type="text" label="Name" />

        <div class="mt-6 flex items-center gap-4">
          <.button variant="primary" phx-disable-with="Saving...">Save Changes</.button>
          <.link navigate={~p"/tags/#{@tag}"} class="text-sm">Cancel</.link>
        </div>
      </.form>
    </Layouts.app>
    """
  end
end
