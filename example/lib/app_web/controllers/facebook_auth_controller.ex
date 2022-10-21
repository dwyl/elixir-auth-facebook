defmodule AppWeb.FacebookAuthController do
  use Phoenix.Controller

  action_fallback(AppWeb.LoginError)

  def login(conn, params) do
    with {:ok, profile} <- ElixirAuthFacebook.handle_callback(conn, params),
         %{email: email} <- profile do
      conn
      |> put_session(:profile, profile)
      |> redirect(to: "/welcome")
      |> halt()
    end
  end
end
