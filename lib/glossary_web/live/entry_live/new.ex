defmodule GlossaryWeb.EntryLive.New do
  use GlossaryWeb, :live_view

  alias Glossary.Entries
  alias Glossary.Entries.Entry

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "New Entry")
     |> assign(:entry, %Entry{})
     |> assign(:form, to_form(Entries.change_entry(%Entry{})))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage entry records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="entry-form" phx-change="validate" phx-submit="create">
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:subtitle]} type="text" label="Subtitle" />

        <footer class="mt-4">
          <.button phx-disable-with="Saving..." variant="primary">Create Entry</.button>
          <.button navigate={~p"/entries"}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("validate", %{"entry" => entry_params}, socket) do
    changeset = Entries.change_entry(socket.assigns.entry, entry_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("create", %{"entry" => entry_params}, socket) do
    params =
      entry_params
      |> Map.put_new("body", "")
      |> Map.put_new("body_text", "")

    case Entries.create_entry(params) do
      {:ok, entry} ->
        {:noreply,
         socket
         |> put_flash(:info, "Entry created successfully")
         |> push_navigate(to: ~p"/entries/#{entry}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
