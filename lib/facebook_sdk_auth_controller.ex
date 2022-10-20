defmodule MyAppWeb.FacebookSdkAuthController do
  use MyAppWeb, :controller

  action_fallback(MyAppWeb.LoginError)

  # obtain an atom-key based map from a string-key  based map
  defp into_atoms(strings) do
    for {k, v} <- strings, into: %{}, do: {String.to_atom(k), v}
  end

  # update a nested key
  defp into_deep(params, key) do
    params
    |> into_atoms()
    |> Map.update!(key, fn pic ->
      pic
      |> Jason.decode!()
      |> into_atoms()
    end)
  end

  def handle(conn, params) do
    profile = into_deep(params, :picture)

    # below is an example of handling the obtained "profile"
    # you save to the database and put the data in the session
    # ( I used a Repo.insert with an "on_conflict" and "conflict_target" clause
    # instead of a find_or_create...)

    case profile do
      %{email: email} ->
        # you want to pass the name or email and ID
        user = MyApp.User.new(email)
        user_token = MyApp.Token.user_generate(user.id)

        conn
        |> fetch_session()
        |> put_session(:user_token, user_token)
        |> put_session(:user_id, user.id)
        |> put_session(:origin, "fb_sdk")
        |> put_session(:profile, profile)
        |> put_view(MyAppWeb.WelcomeView)
        |> redirect(to: "/welcome")
        |> halt()
    end
  end
end
