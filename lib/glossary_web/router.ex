defmodule GlossaryWeb.Router do
  use GlossaryWeb, :router

  import GlossaryWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {GlossaryWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  ## Authentication routes (no login required)

  scope "/", GlossaryWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{GlossaryWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  ## Protected app routes (login required)

  scope "/", GlossaryWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{GlossaryWeb.UserAuth, :require_authenticated}] do
      live "/", Dashboard, :index

      live "/entries", EntryLive.Index, :index
      live "/entries/new", EntryLive.New, :new
      live "/entries/:id", EntryLive.Edit, :edit

      live "/projects", ProjectLive.Index, :index
      live "/projects/new", ProjectLive.New, :new
      live "/projects/:id", ProjectLive.Show, :show
      live "/projects/:id/edit", ProjectLive.Edit, :edit

      live "/topics", TopicLive.Index, :index
      live "/topics/new", TopicLive.New, :new
      live "/topics/:id", TopicLive.Show, :show
      live "/topics/:id/edit", TopicLive.Edit, :edit

      live "/users/settings", UserLive.Settings, :edit
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  # Other scopes may use custom stacks.
  # scope "/api", GlossaryWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:glossary, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: GlossaryWeb.Telemetry
    end
  end
end
