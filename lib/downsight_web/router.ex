defmodule DownsightWeb.Router do
  use DownsightWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {DownsightWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_protected do
    plug :accepts, ["json"]
    plug :authorize
  end

  def authorize(conn, _opts) do
    case conn
         |> fetch_session()
         |> get_session(:us) do
      x when is_nil(x) -> conn |> send_resp(403, "Unauthorized") |> halt()
      _ -> conn
    end
  end

  scope "/", DownsightWeb do
    pipe_through :browser

    live "/", PageLive, :index
  end

  # Other scopes may use custom stacks.

  scope "/api/user", DownsightWeb do
    pipe_through :api

    post "/create", UserController, :create
    post "/login", UserController, :login
  end

  scope "/api/me", DownsightWeb do
    pipe_through :api_protected
    get "/session", UserController, :session
  end

  scope "/api/service", DownsightWeb do
    pipe_through :api_protected
    post "/create", ServiceController, :create
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: DownsightWeb.Telemetry
    end
  end
end
