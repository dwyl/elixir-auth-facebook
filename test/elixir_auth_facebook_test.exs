defmodule ElixirAuthFacebookTest do
  use ExUnit.Case, async: true

  @cb_url if System.get_env("FACEBOOK_HTTPS") == "false",
            do: "http%3A%2F%2Flocalhost%3A4000%2Fauth%2Ffacebook%2Fcallback",
            else: "https%3A%2F%2Flocalhost%2Fauth%2Ffacebook%2Fcallback"

  @url_exchange "https://graph.facebook.com/v15.0/oauth/access_token?client_id=1234&client_secret=ABCD&code=code&redirect_uri=#{@cb_url}&state=1234"

  test "raising on missing env" do
    env_app_id = System.get_env("FACEBOOK_APP_ID")
    env_app_secret = System.get_env("FACEBOOK_APP_SECRET")
    env_app_state = System.get_env("FACEBOOK_STATE")

    if env_app_id == nil,
      do: assert_raise(RuntimeError, "App ID missing", fn -> raise "App ID missing" end)

    if env_app_secret == nil,
      do: assert_raise(RuntimeError, "App secret missing", fn -> raise "App secret missing" end)

    if env_app_state == nil,
      do: assert_raise(RuntimeError, "App state missing", fn -> raise "App state missing" end)
  end

  test "credentials & config" do
    env_app_id = System.get_env("FACEBOOK_APP_ID")
    config_app_id = Application.get_env(:app, :app_id)

    env_app_secret = System.get_env("FACEBOOK_APP_SECRET")
    config_app_secret = Application.get_env(:app, :app_secret)

    assert env_app_id == config_app_id
    assert env_app_id == ElixirAuthFacebook.app_id()
    assert ElixirAuthFacebook.app_id() == env_app_id

    assert env_app_secret == config_app_secret
    assert env_app_secret == ElixirAuthFacebook.app_secret()
    assert ElixirAuthFacebook.app_secret() == env_app_secret

    app_access_token = env_app_id <> "|" <> env_app_secret

    assert ElixirAuthFacebook.app_access_token() == app_access_token
  end

  test "redirect_urls" do
    conn = %Plug.Conn{host: "dwyl.com"}

    assert ElixirAuthFacebook.get_baseurl_from_conn(conn) ==
             "https://dwyl.com"

    conn = %Plug.Conn{host: "localhost", port: 4000}

    assert ElixirAuthFacebook.get_baseurl_from_conn(conn) ==
             "http://localhost:4000"

    callback_url = "/auth/facebook/callback"
    fb_dialog_oauth = "https://www.facebook.com/v15.0/dialog/oauth?"

    assert ElixirAuthFacebook.generate_redirect_url(conn) ==
             "http://localhost:4000" <> callback_url

    conn = %Plug.Conn{scheme: :https, host: "dwyl.com"}

    assert ElixirAuthFacebook.generate_redirect_url(conn) ==
             "https://dwyl.com" <> callback_url

    conn = %Plug.Conn{host: "localhost", port: 4000}

    assert ElixirAuthFacebook.generate_oauth_url(conn) ==
             fb_dialog_oauth <> ElixirAuthFacebook.params_1(conn)

    fb_access_token = "https://graph.facebook.com/v15.0/oauth/access_token?"

    assert ElixirAuthFacebook.access_token_uri("123", conn) ==
             fb_access_token <> ElixirAuthFacebook.params_2("123", conn)

    assert ElixirAuthFacebook.debug_token_uri("123") ==
             "https://graph.facebook.com/debug_token?" <> ElixirAuthFacebook.params_3("123")

    fb_profile = "https://graph.facebook.com/v15.0/me?fields=id,email,name,picture"

    assert ElixirAuthFacebook.graph_api("access") ==
             fb_profile <> "&" <> "access"
  end

  test "state" do
    env_app_state = System.get_env("FACEBOOK_STATE")

    config_app_state = Application.get_env(:app, :app_state)

    assert env_app_state == config_app_state

    assert ElixirAuthFacebook.get_state() == env_app_state
    assert ElixirAuthFacebook.check_state(env_app_state) == true

    state = "123"
    assert ElixirAuthFacebook.check_state(state) == false
  end

  test "build params" do
    conn = %Plug.Conn{scheme: :https, host: "dwyl.com"}

    expected =
      "client_id=1234&redirect_uri=https%3A%2F%2Fdwyl.com%2Fauth%2Ffacebook%2Fcallback&scope=public_profile&state=1234"

    assert ElixirAuthFacebook.params_1(conn) == expected

    expected = "access_token=1234%7CABCD&input_token=aze"

    assert ElixirAuthFacebook.params_3("aze") == expected

    expected =
      "client_id=1234&client_secret=ABCD&code=code&redirect_uri=https%3A%2F%2Fdwyl.com%2Fauth%2Ffacebook%2Fcallback&state=1234"

    assert ElixirAuthFacebook.params_2("code", conn) == expected
  end

  test "exchange_id" do
    profile = %{id: 1}
    assert ElixirAuthFacebook.exchange_id(profile) == %{fb_id: 1}
  end

  test "check_profile" do
    profile = %{"a" => 1, "b" => 2, "id" => 12, "picture" => %{"data" => %{"url" => 3}}}
    expected = %{a: 1, b: 2, id: 12, picture: %{"data" => %{"url" => 3}}}
    assert ElixirAuthFacebook.into_atoms(profile) == expected

    expected = %{a: 1, b: 2, id: 12, picture: %{url: 3}}
    assert ElixirAuthFacebook.nice_map(profile) == expected

    conn = %Plug.Conn{
      assigns: %{access_token: "token", profile: profile}
    }

    res = %{access_token: "token", a: 1, b: 2, fb_id: 12, picture: %{url: 3}}
    assert ElixirAuthFacebook.check_profile(conn) == {:ok, res}
  end

  test "captures errors" do
    conn = %Plug.Conn{assigns: %{access_token: "AT", is_valid: true}}

    assert ElixirAuthFacebook.get_profile(conn).assigns.profile["error"]["message"] ==
             "Invalid OAuth access token - Cannot parse access token"

    conn = %Plug.Conn{assigns: %{data: %{"access_token" => "AT"}}}

    assert ElixirAuthFacebook.get_data(conn).assigns.data["is_valid"] == nil

    conn = %Plug.Conn{assigns: %{data: %{"error" => %{"message" => "test"}}}}
    assert ElixirAuthFacebook.get_data({:error, "test"}) == {:error, {:get_data, "test"}}
    assert ElixirAuthFacebook.get_data(conn) == {:error, {:get_data, "test"}}

    assert ElixirAuthFacebook.check_profile({:error, "test"}) ==
             {:error, {:check_profile, "test"}}

    assert ElixirAuthFacebook.check_profile(conn) == {:error, {:check_profile, "test"}}

    assert ElixirAuthFacebook.get_profile({:error, "test"}) ==
             {:error, {:get_profile, "test"}}

    conn = %Plug.Conn{assigns: %{is_valid: nil}}

    assert ElixirAuthFacebook.get_profile(conn) ==
             {:error, {:get_profile, "renew your credentials"}}
  end

  test "decode_reponse" do
    url = "https://jsonplaceholder.typicode.com/todos/1"
    assert ElixirAuthFacebook.decode_response(url)["id"] == 1
  end

  test "handle user deny dialog" do
    assert ElixirAuthFacebook.handle_callback(%Plug.Conn{}, %{"error" => "ok"}) ==
             {:error, {:access, "ok"}}
  end
end
