defmodule ElixirAuthFacebook do
  import Plug.Conn

  @moduledoc """
  Snippet to enable SSR Facebook Login for web apps.

  Two functions are exposed:
  generate_oauth_url(conn)
  handle_callback(conn, params, f \\ terminate)

  nb: if you target Android or IOS, use the SDK.
  """

  @default_callback_path "/auth/facebook/callback"
  @default_scope "public_profile"
  @fb_dialog_oauth "https://www.facebook.com/v15.0/dialog/oauth?"
  @fb_access_token "https://graph.facebook.com/v15.0/oauth/access_token?"
  @fb_debug "https://graph.facebook.com/debug_token?"
  @fb_profile "https://graph.facebook.com/v15.0/me?fields=id,email,name,picture"

  # ------ Definition of Credentials
  def app_id(),
    do:
      System.get_env("FACEBOOK_APP_ID") ||
        Application.get_env(:elixir_auth_facebook, :app_id) ||
        raise("""
        App ID missing
        """)

  def app_secret() do
    System.get_env("FACEBOOK_APP_SECRET") ||
      Application.get_env(:elixir_auth_facebook, :app_secret) ||
      raise """
      App secret missing
      """
  end

  def app_access_token(), do: app_id() <> "|" <> app_secret()

  # -------- callback URL

  def check_callback_url(url) do
    if String.at(url, 0) != "/",
      do:
        raise("""
        Bad callback url. It must start with "/"
        """)
  end

  @doc """
  derives the URL from the "conn" struct and the input
  """
  def generate_redirect_url(%Plug.Conn{host: "localhost"}) do
    check_callback_url(@default_callback_path)
    "http://localhost:4000/" <> @default_callback_path
  end

  def generate_redirect_url(%Plug.Conn{scheme: sch, host: h}) do
    check_callback_url(@default_callback_path)

    Atom.to_string(sch) <>
      "://" <>
      h <>
      @default_callback_path
  end

  # ------- Definition of Dialog Login entry point

  @doc """
  Generates the url that opens Login dialog.
  """
  def generate_oauth_url(conn) do
    @fb_dialog_oauth <> params_1(conn)
  end

  # ---------- Definition of the URLs
  @doc """
  Generates the url for the exchange "code" to "access_token".
  """
  def access_token_uri(code, conn) do
    @fb_access_token <> params_2(code, conn)
  end

  @doc """
  Generates the url for Access Token inspection.
  """
  def debug_token_uri(token), do: @fb_debug <> params_3(token)

  @doc """
  Generates the url for session info
  """
  defp session_info_url(token) do
    @fb_access_token <>
      "grant_type=fb_attenuate_token&client_id=" <>
      app_id() <>
      "&fb_exchange_token=" <>
      token
  end

  @doc """
  Generates the Graph API url to query for users data.
  """
  def graph_api(access), do: @fb_profile <> "&" <> access

  # ------- Error handling function
  @doc """
  Function to document how to terminate errors. Use flash, redirect...
  """
  def terminate(conn, message, path) do
    conn
    |> Phoenix.Controller.put_flash(:error, inspect(message))
    |> Phoenix.Controller.redirect(to: path)
    |> halt()
  end

  # ------- MAIN
  def handle_callback(conn, params, term \\ &terminate/3)

  # User denies Login dialog
  def handle_callback(conn, %{"error" => message}, term) do
    term.(conn, {:handle_callback, message}, "/")
  end

  @doc """
  We receive the "state" aka as "salt" we sent.
  """
  def handle_callback(conn, %{"state" => state, "code" => code}, term) do
    conn = Plug.Conn.assign(conn, :term, term)

    case check_salt(state) do
      false ->
        term.(conn, "salt false", "/")

      true ->
        code
        |> access_token_uri(conn)
        |> HTTPoison.get!()
        |> Map.get(:body)
        |> Jason.decode!()
        |> then(fn data ->
          conn
          |> Plug.Conn.assign(:data, data)
          |> get_data()
          |> get_session_info()
          |> get_profile()
          |> check_profile()
        end)
    end
  end

  def get_data(%Plug.Conn{assigns: %{data: %{"error" => %{"message" => message}}}} = conn) do
    conn.assigns.term.(conn, {:get_data, message}, "/")
  end

  def get_data(%Plug.Conn{assigns: %{data: %{"access_token" => token}}} = conn) do
    token
    |> debug_token_uri()
    |> HTTPoison.get!()
    |> Map.get(:body)
    |> Jason.decode!()
    |> Map.get("data")
    |> then(fn data ->
      conn
      |> Plug.Conn.assign(:data, data)
      |> Plug.Conn.assign(:access_token, token)
      |> Plug.Conn.assign(:is_valid, data["is_valid"])
    end)
  end

  def get_session_info(%Plug.Conn{assigns: %{data: %{"error" => %{"message" => message}}}} = conn) do
    conn.assigns.term.(conn, {:get_session, message}, "/")
  end

  def get_session_info(%Plug.Conn{assigns: %{is_valid: nil}} = conn) do
    conn.assigns.term.(conn, {:get_session, "renew your credentials"}, "/")
  end

  def get_session_info(%Plug.Conn{assigns: %{access_token: token}} = conn) do
    token
    |> session_info_url()
    |> HTTPoison.get!()
    |> Map.get(:body)
    |> Jason.decode!()
    |> then(fn data ->
      conn
      |> Plug.Conn.assign(:session_info, data["access_token"])
    end)
  end

  def get_profile(%Plug.Conn{assigns: %{data: %{"error" => %{"message" => message}}}} = conn) do
    conn.assigns.term.(conn, {:get_profile, message}, "/")
  end

  def get_profile(%Plug.Conn{assigns: %{is_valid: nil}} = conn) do
    conn.assigns.term.(conn, {:get_profile, "renew your credentials"}, "/")
  end

  def get_profile(%Plug.Conn{assigns: %{session_info: nil}} = conn) do
    conn.assigns.term.(conn, {:get_profile_session, "renew your credentials"}, "/")
  end

  def get_profile(%Plug.Conn{assigns: %{access_token: token, is_valid: true}} = conn) do
    URI.encode_query(%{"access_token" => token})
    |> graph_api()
    |> HTTPoison.get!()
    |> Map.get(:body)
    |> Jason.decode!()
    |> then(fn data ->
      Plug.Conn.assign(conn, :profile, data)
    end)
  end

  def check_profile(%Plug.Conn{assigns: %{profile: %{"error" => %{"message" => message}}}} = conn) do
    conn.assigns.term.(conn, {:check_profile, message}, "/")
  end

  def check_profile(%Plug.Conn{
        assigns: %{access_token: token, session_info: session_info, profile: profile}
      }) do
    profile =
      for({k, v} <- profile, into: %{}, do: {String.to_atom(k), v})
      |> Map.merge(%{access_token: token})
      |> Map.merge(%{session_info: session_info})
      |> exchange_id()

    {:ok, profile}
  end

  # ---------- Helper on cleaning the profile
  @doc """
  Facebook gives and ID. We replace "id" to "fb_id" to avoid confusion in the returned data
  """
  def exchange_id(profile) do
    profile
    |> Map.put_new(:fb_id, profile.id)
    |> Map.delete(:id)
  end

  # ---------- Helpers on salt and query params
  def get_salt() do
    Application.get_env(:live_map, LiveMapWeb.Endpoint)
    |> List.keyfind(:live_view, 0)
    |> then(fn {:live_view, [signing_salt: val]} ->
      val
    end) ||
      raise """
      Missing Endpoint signing salt
      """
  end

  def check_salt(state) do
    get_salt() == state
  end

  defp params_1(conn) do
    URI.encode_query(%{
      "client_id" => app_id(),
      "state" => get_salt(),
      "redirect_uri" => generate_redirect_url(conn),
      "scope" => @default_scope
    })
  end

  defp params_2(code, conn) do
    URI.encode_query(%{
      "client_id" => app_id(),
      "state" => get_salt(),
      "redirect_uri" => generate_redirect_url(conn),
      "code" => code,
      "client_secret" => app_secret()
    })
  end

  defp params_3(token) do
    URI.encode_query(%{
      "access_token" => app_access_token(),
      "input_token" => token
    })
  end
end
