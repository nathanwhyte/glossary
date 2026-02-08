defmodule GlossaryWeb.TopicLive.New do
  use GlossaryWeb, :live_view

  alias Glossary.Topics
  alias Glossary.Topics.Topic

  @impl true
  def mount(_params, _session, socket) do
    changeset = Topics.change_topic(%Topic{})

    {:ok,
     socket
     |> assign(:page_title, "New Topic")
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate", %{"topic" => topic_params}, socket) do
    changeset =
      %Topic{}
      |> Topics.change_topic(topic_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"topic" => topic_params}, socket) do
    case Topics.create_topic(topic_params) do
      {:ok, topic} ->
        {:noreply,
         socket
         |> put_flash(:info, "Topic created successfully.")
         |> push_navigate(to: ~p"/topics/#{topic}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.live_component
        module={GlossaryWeb.SearchModal}
        id="global-search-modal"
      />

      <LiveLayouts.back_link navigate={~p"/topics"} text="Back to Topics" />

      <.header>
        New Topic
        <:subtitle>Create a new topic to tag entries.</:subtitle>
      </.header>

      <.form for={@form} id="topic-form" phx-change="validate" phx-submit="save" class="mt-6">
        <.input field={@form[:name]} type="text" label="Name" />

        <div class="mt-6 flex items-center gap-4">
          <.button variant="primary" phx-disable-with="Creating...">Create Topic</.button>
          <.link navigate={~p"/topics"} class="text-sm">Cancel</.link>
        </div>
      </.form>
    </Layouts.app>
    """
  end
end
