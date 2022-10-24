defmodule ElixirAuthFacebook do
  import Plug.Conn
  alias ElixirAuthFacebook.HTTPoisonMock

  @moduledoc """
  This module exposes two functions to enable Facebook Login
  from the server:

  - generate_oauth_url/1 takes the conn from the controller
  (to get the domain) and returns an URL with a query string.
  We reach the Facebook dialogue form with this URL.

  - handle_callback/2 is the callback of the endpoint that receives
  Facebook's response
  """

  @default_callback_path "/auth/facebook/callback"
  @default_scope "public_profile"
  @fb_dialog_oauth "https://www.facebook.com/v15.0/dialog/oauth?"
  @fb_debug "https://graph.facebook.com/debug_token?"
  @fb_access_token "https://graph.facebook.com/v15.0/oauth/access_token?"
  @fb_profile "https://graph.facebook.com/v15.0/me?fields=id,email,name,picture"

  # ------ APIs ----------------

  @doc """
  Generates the URL to navigate to the Facebook Login dialogue.

  This URL is passed into the assigns for the template.

  ## Example
    ```elixir
    oauth_facebook_url = ElixirAuthFacebook.generate_oauth_url(conn)
    render(conn, "index.html", oauth_facebook_url: oauth_facebook_url
    ```
  """
  def generate_oauth_url(conn), do: @fb_dialog_oauth <> params_1(conn)

  @doc """
    The callback triggered after receiving Facebook's response.
    You create a "GET /auth/facebook/callback" endpoint and
    a controller where you implement `handle_callback(conn, params)`

    It receives Facebook's payload in the params and delivers
    a tuple `{:ok, profile}`.
    ```elixir
    profile = %{
      access_token: "EAAFNaUA6VI8BAPkCCVV6q0U0tf7...",
      email: "xxxxx",
      fb_id: "10223726006128074",
      name: "Harry Potter",
      picture: %{
        "data" => %{
          "height" => 50,
          "is_silhouette" => false,
          "url" => "xxxxx",
          "width" => 50
        }
      }
    }
    ```
  """

  # user denies dialog
  def handle_callback(_conn, %{"error" => message}) do
    {:error, {:access, message}}
  end

  # first call: gets the access_token from the received "code" and app credentials
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

  # _______ private functions ______________________________________

  # second call: from access_token to user_id
  def get_data({:error, message}), do: {:error, {:get_data, message}}

  def get_data(%Plug.Conn{assigns: %{data: %{"error" => %{"message" => message}}}}) do
    {:error, {:get_data, message}}
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

  # third call: from user_id to user_profile
  def get_profile({:error, message}), do: {:error, {:get_profile, message}}

  def get_profile(%Plug.Conn{assigns: %{is_valid: nil}}) do
    {:error, {:get_profile2, "renew your credentials"}}
  end

  def get_profile(%Plug.Conn{assigns: %{access_token: token}} = conn) do
    URI.encode_query(%{"access_token" => token})
    |> graph_api()
    |> decode_response()
    |> then(fn data ->
      assign(conn, :profile, data)
    end)
  end

  # cleaning the received user's profile
  def check_profile({:error, message}), do: {:error, {:check_profile, message}}

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

  # ------ Retrieve App Credentials from ENV or CONFIG ir RAISE -----
  def app_id do
    System.get_env("FACEBOOK_APP_ID") ||
      Application.get_env(:elixir_auth_facebook, :app_id) ||
      raise("""
      App ID missing
      """)
  end

  def app_secret do
    System.get_env("FACEBOOK_APP_SECRET") ||
      Application.get_env(:elixir_auth_facebook, :app_secret) ||
      raise """
      App secret missing
      """
  end

  def app_access_token, do: app_id() <> "|" <> app_secret()

  # anti-CSRF
  def get_state do
    System.get_env("FACEBOOK_STATE") ||
      Application.get_env(:elixir_auth_facebook, :app_state) ||
      raise """
      App state missing
      """
  end

  # ---------- Definition of the URLs ---------
  def get_baseurl_from_conn(%{host: h, port: p}) when h == "localhost" do
    (p != 4000 && "https://localhost") || "http://#{h}:#{p}"
  end

  def get_baseurl_from_conn(%{host: h}), do: "https://#{h}"

  # derives the URL from the "conn" struct and the input
  def generate_redirect_url(conn) do
    get_baseurl_from_conn(conn) <> @default_callback_path
  end

  # Generates the url for the exchange "code" to "access_token".
  def access_token_uri(code, conn), do: @fb_access_token <> params_2(code, conn)

  # Generates the url for Access Token inspection.
  def debug_token_uri(token), do: @fb_debug <> params_3(token)

  # Generates the Graph API url to query for users data.
  def graph_api(access), do: @fb_profile <> "&" <> access

  # ------ Private Helpers -------------------
  # Utility function: receives an URL and provides the response body
  # when testing, it uses a mock version of the HTTP call, otherwise the original version
  def decode_response(url) do
    inject =
      (Application.get_env(:elixir_auth_facebook, :mode) == :test && HTTPoisonMock) ||
        HTTPoison

    url
    |> inject.get!()
    |> Map.get(:body)
    |> Jason.decode!()
  end

  # utility to format the profile map with atom keys
  def into_atoms(strings) do
    for {k, v} <- strings, into: %{}, do: {String.to_atom(k), v}
  end

  # utility to transform and move deeply the "string-keyed" map into an "atom-keyed" map
  def nice_map(map) do
    map
    |> into_atoms()
    |> Map.update!(:picture, fn pic ->
      pic["data"]
      |> into_atoms()
    end)
  end

  # utility to replace "id" to "fb_id" to avoid confusion in the returned data
  def exchange_id(profile) do
    profile
    |> Map.put_new(:fb_id, profile.id)
    |> Map.delete(:id)
  end

  # ----- State anti-CSRF check -------------
  # verify that the received state is equal to the system state
  def check_state(state), do: get_state() == state

  # ----Building query strings for the 3 HTTP calls -------
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
