defmodule MyAppWeb.FacebookAuthController do
  use LiveMapWeb, :controller

  def custom_term(conn, message, path),
    do:
      conn
      |> Phoenix.Controller.redirect(to: path)
      |> Plug.Conn.halt()

  def login(conn, params) do
    # example with modified termination function: &custom_term/3

    {:ok, profile} = ElixirAuthFacebook.handle_callback(conn, params, &custom_term/3)

    with %{email: email} <- profile do
      user = LiveMap.User.new(email)
      user_token = LiveMap.Token.user_generate(user.id)

      conn
      |> put_session(:user_token, user_token)
      |> put_session(:user_id, user.id)
      |> put_session(:profile, profile)
      |> redirect(to: "/welcome")
      |> halt()
    else
      _ -> render(conn, "index.html")
    end
  end
end
