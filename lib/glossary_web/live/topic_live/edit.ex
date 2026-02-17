defmodule GlossaryWeb.TopicLive.Edit do
  use GlossaryWeb, :live_view

  alias Glossary.Topics

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    topic = Topics.get_topic!(id)
    changeset = Topics.change_topic(topic)

    {:ok,
     socket
     |> assign(:page_title, "Edit Topic")
     |> assign(:topic, topic)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate", %{"topic" => topic_params}, socket) do
    changeset =
      socket.assigns.topic
      |> Topics.change_topic(topic_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"topic" => topic_params}, socket) do
    case Topics.update_topic(socket.assigns.topic, topic_params) do
      {:ok, topic} ->
        {:noreply,
         socket
         |> put_flash(:info, "Topic updated successfully.")
         |> push_navigate(to: ~p"/topics/#{topic}")}

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

      <LiveLayouts.back_link navigate={~p"/topics"} text="Back to Topics" />

      <.header>
        Edit Topic
        <:subtitle>Update the topic name.</:subtitle>
      </.header>

      <.form for={@form} id="topic-form" phx-change="validate" phx-submit="save" class="mt-6">
        <.input field={@form[:name]} type="text" label="Name" />

        <div class="mt-6 flex items-center gap-4">
          <.button variant="primary" phx-disable-with="Saving...">Save Changes</.button>
          <.link navigate={~p"/topics/#{@topic}"} class="text-sm">Cancel</.link>
        </div>
      </.form>
    </Layouts.app>
    """
  end
end
