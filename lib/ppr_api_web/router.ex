defmodule PprApiWeb.Router do
  use PprApiWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PprApiWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api/v1", PprApiWeb do
    pipe_through :api
    resources "/residential/sales", API.ResidentialSaleController
  end

  scope "/", PprApiWeb do
    pipe_through :browser

    get "/fonts/:font_name", FontController, :get_font

    live "/fetches", FetchLive.Index, :index
    live "/residential/sales", ResidentialSaleLive.Index, :index
    live "/", ResidentialSaleLive.Index, :index
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:ppr_api, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PprApiWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
