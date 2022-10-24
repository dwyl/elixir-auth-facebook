defmodule ElixirAuthFacebookTest do
  use ExUnit.Case, async: true

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
    config_app_id = Application.get_env(:elixir_auth_facebook, :app_id)

    env_app_secret = System.get_env("FACEBOOK_APP_SECRET")
    config_app_secret = Application.get_env(:elixir_auth_facebook, :app_secret)

    if env_app_id != nil do
      assert(env_app_id == config_app_id)
      assert env_app_id == ElixirAuthFacebook.app_id()
    end

    if env_app_secret != nil do
      assert env_app_secret == config_app_secret
      assert env_app_secret == ElixirAuthFacebook.app_secret()
    end

    if env_app_id != nil && env_app_secret != nil do
      app_access_token = env_app_id <> "|" <> env_app_secret
      assert ElixirAuthFacebook.app_access_token() == app_access_token
    end
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

    conn = %Plug.Conn{host: "dwyl.com"}

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
    config_app_state = Application.get_env(:elixir_auth_facebook, :app_state)

    if env_app_state != nil do
      assert env_app_state == config_app_state

      assert ElixirAuthFacebook.get_state() == config_app_state
      assert ElixirAuthFacebook.check_state(config_app_state) == true

      state = "123"
      assert ElixirAuthFacebook.check_state(state) == false
    end
  end

  test "build params HTTPS" do
    conn = %Plug.Conn{host: "dwyl.com"}
    url = "https%3A%2F%2Fdwyl.com%2Fauth%2Ffacebook%2Fcallback"
    expected = "client_id=1234&redirect_uri=#{url}&scope=public_profile&state=1234"

    assert ElixirAuthFacebook.params_1(conn) == expected

    expected = "access_token=1234%7CABCD&input_token=aze"

    assert ElixirAuthFacebook.params_3("aze") == expected

    expected = "client_id=1234&client_secret=ABCD&code=code&redirect_uri=#{url}&state=1234"

    assert ElixirAuthFacebook.params_2("code", conn) == expected
  end

  test "build params HTTP" do
    conn = %Plug.Conn{host: "localhost", port: 4000}
    url = "http%3A%2F%2Flocalhost%3A4000%2Fauth%2Ffacebook%2Fcallback"
    expected = "client_id=1234&redirect_uri=#{url}&scope=public_profile&state=1234"

    assert ElixirAuthFacebook.params_1(conn) == expected

    expected = "access_token=1234%7CABCD&input_token=aze"

    assert ElixirAuthFacebook.params_3("aze") == expected

    expected = "client_id=1234&client_secret=ABCD&code=code&redirect_uri=#{url}&state=1234"

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
    assert ElixirAuthFacebook.get_data({:error, "test"}) == {:error, {:get_data, "test"}}

    assert ElixirAuthFacebook.get_profile({:error, "test"}) ==
             {:error, {:get_profile, "test"}}

    assert ElixirAuthFacebook.check_profile({:error, "test"}) ==
             {:error, {:check_profile, "test"}}

    assert ElixirAuthFacebook.get_profile(%Plug.Conn{assigns: %{is_valid: nil}}) ==
             {:error, {:get_profile2, "renew your credentials"}}
  end

  test "errors" do
    conn = %Plug.Conn{host: "localhost", port: 4000, assigns: %{data: %{"access_token" => "A"}}}

    assert ElixirAuthFacebook.get_data(conn) |> ElixirAuthFacebook.get_profile() ==
             {:error, {:get_profile2, "renew your credentials"}}

    conn = %Plug.Conn{assigns: %{data: %{"error" => %{"message" => "test"}}}}
    assert ElixirAuthFacebook.get_data(conn) == {:error, {:get_data, "test"}}
  end

  test "chaining errors" do
    conn = %Plug.Conn{host: "localhost", port: 4000, assigns: %{data: %{"access_token" => "A"}}}

    assert ElixirAuthFacebook.get_data(conn)
           |> ElixirAuthFacebook.get_profile()
           |> ElixirAuthFacebook.check_profile() ==
             {:error, {:check_profile, {:get_profile2, "renew your credentials"}}}

    conn = %Plug.Conn{host: "localhost", port: 4000, assigns: %{data: %{"access_token" => "A"}}}

    assert ElixirAuthFacebook.get_data(conn)
           |> ElixirAuthFacebook.get_profile()
           |> ElixirAuthFacebook.check_profile() ==
             {:error, {:check_profile, {:get_profile2, "renew your credentials"}}}

    #  {:check_profile, {:get_profile, {:get_data, "Error validating client secret."}}}
  end

  test "handle user positive" do
    assert ElixirAuthFacebook.handle_callback(%Plug.Conn{host: "localhost", port: 4000}, %{
             "state" => "1234",
             "code" => "code"
           }) ==
             {:ok,
              %{
                access_token: "AT",
                email: "harry@potter.com",
                fb_id: "10228683763268904",
                is_valid: true,
                name: "Harry Potter",
                picture: %{
                  height: "50",
                  is_silhouette: "false",
                  url: "www.dwyl.com",
                  width: "50"
                }
              }}
  end

  test "handle user deny dialog" do
    assert ElixirAuthFacebook.handle_callback(%Plug.Conn{}, %{"error" => "ok"}) ==
             {:error, {:access, "ok"}}
  end

  test "handle error state" do
    assert ElixirAuthFacebook.handle_callback(%Plug.Conn{}, %{"state" => "123", "code" => "code"}) ==
             {:error, {:state, "Error with the state"}}
  end

  # test "end" do
  #   http = "http%3A%2F%2Flocalhost%3A4000%2Fauth%2Ffacebook%2Fcallback"
  #   Application.put_env(:elixir_auth_facebook, :app_id, "123")

  #   if Application.get_env(:elixir_auth_facebook, :app_id) == "123" do
  #     assert ElixirAuthFacebook.handle_callback(%Plug.Conn{host: "localhost", port: 4000}, %{
  #              "state" => "1234",
  #              "code" => "code"
  #            }) ==
  #              {:error,
  #               {:check_profile,
  #                {:get_profile,
  #                 {:get_data,
  #                  "Error validating application. Cannot get application info due to a system error."}}}}

  #     # back to "normal" value
  #     Application.put_env(:elixir_auth_facebook, :app_id, "1234")
  #   end
  # end
end

# wrong app_id: {:check_profile, {:get_profile, {:get_data, "Error validating application. Cannot get application info due to a system error."}}}
# wrong app_secret: {:check_profile, {:get_profile, {:get_data, "Error validating client secret."}}}
