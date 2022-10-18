defmodule ElixirAuthFacebookTest do
  use ExUnit.Case, async: true

  # TODO: understand this "mock"

  test "credentials & config" do
    env_app_id = System.get_env("FACEBOOK_APP_ID")
    config_app_id = Application.get_env(:elixir_auth_facebook, :app_id)

    assert env_app_id == config_app_id
    assert env_app_id == ElixirAuthFacebook.app_id()

    env_app_secret = System.get_env("FACEBOOK_APP_SECRET")
    config_app_secret = Application.get_env(:elixir_auth_facebook, :app_secret)

    assert env_app_secret == config_app_secret
    assert env_app_secret == ElixirAuthFacebook.app_secret()

    app_access_token = env_app_id <> "|" <> env_app_secret

    assert ElixirAuthFacebook.app_access_token() == app_access_token
  end

  test "check callback" do
    assert ElixirAuthFacebook.check_callback_url("/aze") == nil
  end

  test "redirect_urls" do
    conn = %Plug.Conn{host: "localhost"}
    callback_url = "/auth/facebook/callback"
    http = "http://localhost:4000"
    assert ElixirAuthFacebook.generate_redirect_url(conn) == http <> callback_url

    conn = %Plug.Conn{scheme: :https, host: "dwyl.com"}

    assert ElixirAuthFacebook.generate_redirect_url(conn) ==
             "https://dwyl.com" <> callback_url
  end

  test "state" do
    salt = "ez1lDCj3"
    assert ElixirAuthFacebook.get_salt() == salt
    assert ElixirAuthFacebook.check_salt(salt) == true
  end

  test "build params" do
    conn = %Plug.Conn{scheme: :https, host: "dwyl.com"}

    res =
      "client_id=366589421180047&redirect_uri=https%3A%2F%2Fdwyl.com%2Fauth%2Ffacebook%2Fcallback&scope=public_profile&state=ez1lDCj3"

    assert ElixirAuthFacebook.params_1(conn) == res

    res =
      "access_token=#{ElixirAuthFacebook.app_id()}%7C#{ElixirAuthFacebook.app_secret()}&input_token=aze"

    assert ElixirAuthFacebook.params_3("aze") == res
  end

  test "exchange_id" do
    profile = %{id: 1}
    assert ElixirAuthFacebook.exchange_id(profile) == %{fb_id: 1}
  end

  test "check_profile" do
    profile = %{"a" => 1, "b" => 2, "id" => 12}

    conn = %Plug.Conn{
      assigns: %{access_token: "token", session_info: "session_info", profile: profile}
    }

    res = %{access_token: "token", session_info: "session_info", a: 1, b: 2, fb_id: 12}
    assert ElixirAuthFacebook.check_profile(conn) == {:ok, res}
  end

  test "get_profile_err" do
    conn = %Plug.Conn{assigns: %{access_token: "token", is_valid: true}}
    res = %{conn | assigns: Map.put_new(conn.assigns, :profile, "data")}

    assert ElixirAuthFacebook.get_profile(conn).assigns.profile["error"]["message"] ==
             "Invalid OAuth access token - Cannot parse access token"
  end

  test "get_session_profile is nil if wrong token" do
    conn = %Plug.Conn{assigns: %{access_token: "token"}}
    assert ElixirAuthFacebook.get_session_info(conn).assigns.session_info == nil
  end

  test "get_data detects wrong token" do
    conn = %Plug.Conn{assigns: %{data: %{"access_token" => "token"}}}

    assert ElixirAuthFacebook.get_data(conn).assigns.data["is_valid"] == false
  end

  def mod_term(conn, msg, pth), do: conn
end
