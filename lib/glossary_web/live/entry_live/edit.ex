defmodule GlossaryWeb.EntryLive.Edit do
  use GlossaryWeb, :live_view

  alias Glossary.Entries
  alias Glossary.Entries.Entry

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.form for={@form} id="entry-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:subtitle]} type="text" label="Subtitle" />

        <div class="mt-4">
          <label class="sr-only block text-sm font-semibold">Body</label>
          <div
            id="tiptap-editor"
            phx-hook="TiptapEditor"
            data-value={@form[:body].value}
            class="mt-2"
          >
            <div data-editor="body" id="tiptap-content" phx-update="ignore" class="tiptap-editor" />
            <input
              type="hidden"
              name="entry[body]"
              data-editor-hidden="body"
              value={@form[:body].value}
            />
            <input
              type="hidden"
              name="entry[body_text]"
              data-editor-hidden="body_text"
              value={@form[:body_text].value}
            />
          </div>
        </div>

        <footer class="mt-4">
          <.button phx-disable-with="Saving..." variant="primary">Save Entry</.button>
          <.button navigate={return_path(@return_to, @entry)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    entry = Entries.get_entry!(id)

    socket
    |> assign(:page_title, "Edit Entry")
    |> assign(:entry, entry)
    |> assign(:form, to_form(Entries.change_entry(entry)))
  end

  defp apply_action(socket, :new, _params) do
    entry = %Entry{}

    socket
    |> assign(:page_title, "New Entry")
    |> assign(:entry, entry)
    |> assign(:form, to_form(Entries.change_entry(entry)))
  end

  @impl true
  def handle_event("validate", %{"entry" => entry_params}, socket) do
    changeset = Entries.change_entry(socket.assigns.entry, entry_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"entry" => entry_params}, socket) do
    save_entry(socket, socket.assigns.live_action, entry_params)
  end

  defp save_entry(socket, :edit, entry_params) do
    case Entries.update_entry(socket.assigns.entry, entry_params) do
      {:ok, entry} ->
        {:noreply,
         socket
         |> put_flash(:info, "Entry updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, entry))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_entry(socket, :new, entry_params) do
    case Entries.create_entry(entry_params) do
      {:ok, entry} ->
        {:noreply,
         socket
         |> put_flash(:info, "Entry created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, entry))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _entry), do: ~p"/entries"
  defp return_path("show", entry), do: ~p"/entries/#{entry}"
end
