defmodule AppWeb.WelcomeController do
  use Phoenix.Controller

  def index(conn, _) do
    profile = get_session(conn, :profile)

    conn
    |> put_view(AppWeb.WelcomeView)
    |> render("welcome.html", profile: profile)
  end
end
