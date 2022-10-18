defmodule MyAppWeb.WelcomeController do
  use LiveMapWeb, :controller

  def index(conn, _) do
    profile = get_session(conn, :profile)

    user_token = get_session(conn, :user_token)
    conn = assign(conn, :user_token, user_token)

    render(conn, "welcome.html", profile: profile)
  end
end
