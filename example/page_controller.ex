defmodule MyAppWeb.PageController do
  use LiveMapWeb, :controller

  def index(conn, _params) do
    oauth_facebook_url = ElixirAuthFacebook.generate_oauth_url(conn)

    conn
    |> render("index.html",
      oauth_facebook_url: oauth_facebook_url
    )
  end
end
