defmodule ElixirAuthFacebook.HTTPoisonMock do
  @moduledoc """
  Mock the HTTP calls to FB for testing
  """

  @app_id Application.compile_env(:elixir_auth_facebook, :app_id)
  @app_secret Application.compile_env(:elixir_auth_facebook, :app_secret)
  @app_state Application.compile_env(:elixir_auth_facebook, :app_state)

  @http "http%3A%2F%2Flocalhost%3A4000%2Fauth%2Ffacebook%2Fcallback"

  # token exchange endpoint
  # @wrong_app_id "https://graph.facebook.com/v15.0/oauth/access_token?client_id=123&client_secret=ABCD&code=code&redirect_uri=#{@http}&state=1234"
  # def get!(@wrong_app_id) do
  #   IO.puts("wrong")
  #   {:error, "Error validating application. Cannot get application info due to a system error."}
  # end

  @url_http_exchange "https://graph.facebook.com/v15.0/oauth/access_token?client_id=#{@app_id}&client_secret=#{@app_secret}&code=code&redirect_uri=#{@http}&state=#{@app_state}"

  @doc false
  def get!(@url_http_exchange) do
    %{
      host: "localhost",
      port: 4000,
      body: Jason.encode!(%{"access_token" => "AT", "token_type" => "bearer"})
    }
  end

  # user id retrieve with token in data
  @url_data "https://graph.facebook.com/debug_token?access_token=#{@app_id}%7CABCD&input_token=AT"
  @doc false
  def get!(@url_data) do
    %{
      body:
        Jason.encode!(%{
          access_token: "AT",
          data: %{"app_id" => "1234", "is_valid" => "true"}
        })
    }
  end

  # simulate wrong token
  @url_data_wrong "https://graph.facebook.com/debug_token?access_token=#{@app_id}%7CABCD&input_token=A"
  @doc false
  def get!(@url_data_wrong) do
    %{
      body:
        Jason.encode!(%{
          access_token: "A",
          data: %{"is_valid" => nil}
        })
    }
  end

  # user profile retrieve with id and token
  @url_profile "https://graph.facebook.com/v15.0/me?fields=id,email,name,picture&access_token=AT"
  @doc false
  def get!(@url_profile) do
    %{
      body:
        Jason.encode!(%{
          access_token: "AT",
          is_valid: true,
          email: "harry@potter.com",
          id: "10228683763268904",
          name: "Harry Potter",
          picture: %{
            "data" => %{
              "height" => "50",
              "is_silhouette" => "false",
              "url" => "www.dwyl.com",
              "width" => "50"
            }
          }
        })
    }
  end
end
