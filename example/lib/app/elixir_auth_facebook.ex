defmodule ElixirAuthFacebook do
  import Plug.Conn

  @moduledoc """
  This module exposes two functions to enable Facebook Login
  from the server

  - "generate_oauth_url" : takes the conn from the controller
  (to get the domain) and returns an URL with a query string.
  We reach Facebook with this URL.

  - "handle_callback": the callback of the endpoint that receives
  Facebook's response
  """

  @https "https://localhost:443"
  @default_callback_path "/auth/facebook/callback"
  @default_scope "public_profile"
  @fb_dialog_oauth "https://www.facebook.com/v15.0/dialog/oauth?"
  @fb_access_token "https://graph.facebook.com/v15.0/oauth/access_token?"
  @fb_debug "https://graph.facebook.com/debug_token?"
  @fb_profile "https://graph.facebook.com/v15.0/me?fields=id,email,name,picture"

  # ------ Returns
  @doc """
  Generates the url that opens Login dialog.
  """
  def generate_oauth_url(conn), do: @fb_dialog_oauth <> params_1(conn)

  # ------- MAIN -----------
  # user denies dialog
  def handle_callback(_conn, %{"error" => message}) do
    {:error, {:access, message}}
  end

  def handle_callback(conn, %{"state" => state, "code" => code}) do
    case check_state(state) do
      false ->
        {:error, {:state, "Error with the state"}}

      true ->
        code
        |> access_token_uri(conn)
        |> decode_response()
        |> then(fn data ->
          conn
          |> assign(:data, data)
          |> get_data()
          |> get_profile()
          |> check_profile()
        end)
    end
  end

  def get_data({:error, message}), do: {:error, {:get_data, message}}

  def get_data(%Plug.Conn{assigns: %{data: %{"error" => %{"message" => message}}}}) do
    # OK
    IO.puts("get_Data 2")
    {:error, {:get_data2, message}}
  end

  def get_data(%Plug.Conn{assigns: %{data: %{"access_token" => token}}} = conn) do
    token
    |> debug_token_uri()
    |> decode_response()
    |> Map.get("data")
    |> then(fn data ->
      conn
      |> assign(:data, data)
      |> assign(:access_token, token)
      |> assign(:is_valid, data["is_valid"])
    end)
  end

  def get_profile({:error, message}), do: {:error, {:get_profile0, message}}
  # OK

  # def get_profile(%Plug.Conn{assigns: %{data: %{"error" => %{"message" => message}}}}) do
  #   {:error, {:get_profile1, message}}
  # end

  def get_profile(%Plug.Conn{assigns: %{is_valid: nil}}) do
    #  OK
    {:error, {:get_profile2, "renew your credentials"}}
  end

  def get_profile(%Plug.Conn{assigns: %{access_token: token, is_valid: true}} = conn) do
    URI.encode_query(%{"access_token" => token})
    |> graph_api()
    |> decode_response()
    |> then(fn data ->
      assign(conn, :profile, data)
    end)
  end

  def check_profile({:error, message}), do: {:error, {:check_profile0, message}}
  # OK

  # def check_profile(%Plug.Conn{assigns: %{is_valid: nil}}) do
  #   {:error, {:check_profile1, "invalid"}}
  # end

  def check_profile(%Plug.Conn{assigns: %{data: %{"error" => %{"message" => message}}}}) do
    {:error, {:check_profile2, message}}
  end

  def check_profile(%Plug.Conn{
        assigns: %{access_token: token, profile: profile}
      }) do
    profile =
      profile
      |> nice_map()
      |> Map.put(:access_token, token)
      |> exchange_id()

    {:ok, profile}
  end

  # ------ Definition of Credentials
  #  "366589421180047"
  def app_id() do
    System.get_env("FACEBOOK_APP_ID") ||
      Application.get_env(:elixir_auth_facebook, :app_id) ||
      raise("""
      App ID missing
      """)
  end

  # "a7f31cd0acd223dd63af686842c3f224"
  def app_secret() do
    System.get_env("FACEBOOK_APP_SECRET") ||
      Application.get_env(:elixir_auth_facebook, :app_secret) ||
      raise """
      App secret missing
      """
  end

  # "366589421180047|a7f31cd0acd223dd63af686842c3f224"
  def app_access_token(), do: app_id() <> "|" <> app_secret()

  # ---------- Definition of the URLs

  # derives the URL from the "conn" struct and the input
  def generate_redirect_url(%Plug.Conn{host: "localhost"}) do
    @https <> @default_callback_path
  end

  def generate_redirect_url(%Plug.Conn{scheme: sch, host: h} = _conn),
    do: Atom.to_string(sch) <> "://" <> h <> @default_callback_path

  # Generates the url for the exchange "code" to "access_token".
  def access_token_uri(code, conn), do: @fb_access_token <> params_2(code, conn)

  # Generates the url for Access Token inspection.
  def debug_token_uri(token), do: @fb_debug <> params_3(token)

  # Generates the Graph API url to query for users data.
  def graph_api(access), do: @fb_profile <> "&" <> access

  # ------ Private Helpers -------------

  # utility function: receives an url and provides the response body
  def decode_response(url) do
    url
    |> HTTPoison.get!()
    |> Map.get(:body)
    |> Jason.decode!()
  end

  # ---  cleaning the profile --------
  def into_atoms(strings) do
    for {k, v} <- strings, into: %{}, do: {String.to_atom(k), v}
  end

  # deep dive into the map
  def nice_map(map) do
    map
    |> into_atoms()
    |> Map.update!(:picture, fn pic ->
      pic["data"]
      |> into_atoms()
    end)
  end

  # FB gives and ID. We replace "id" to "fb_id"
  # to avoid confusion in the returned data
  def exchange_id(profile) do
    profile
    |> Map.put_new(:fb_id, profile.id)
    |> Map.delete(:id)
  end

  # ----- Helpers on state -------

  # we pick the salt from the Endpoint as anti-CSRF check
  def get_state() do
    Application.get_env(:live_map, LiveMapWeb.Endpoint)
    |> List.keyfind(:live_view, 0)
    |> then(fn {:live_view, [signing_salt: val]} ->
      val
    end)
  end

  # verify that the received state is equal to the system state
  def check_state(state), do: get_state() == state

  # ----building query strings ------
  def params_1(conn) do
    URI.encode_query(
      %{
        "client_id" => app_id(),
        "state" => get_state(),
        "redirect_uri" => generate_redirect_url(conn),
        "scope" => @default_scope
      },
      :rfc3986
    )
  end

  def params_2(code, conn) do
    URI.encode_query(
      %{
        "client_id" => app_id(),
        "state" => get_state(),
        "redirect_uri" => generate_redirect_url(conn),
        "code" => code,
        "client_secret" => app_secret()
      },
      :rfc3986
    )
  end

  def params_3(token) do
    URI.encode_query(
      %{
        "access_token" => app_access_token(),
        "input_token" => token
      },
      :rfc3986
    )
  end
end
