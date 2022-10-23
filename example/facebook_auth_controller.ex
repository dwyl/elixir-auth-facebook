defmodule AppWeb.FacebookAuthController do
  use Phoenix.Controller

  def login(conn, params) do
    with {:ok, profile} <- ElixirAuthFacebook.handle_callback(conn, params) do
      conn
      |> put_session(:profile, profile)
      |> render("index.html", oauth_facebook_url: oauth_facebook_url)
    end
  end
end
