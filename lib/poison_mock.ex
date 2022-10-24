defmodule HTTPoisonMock do
  @app_id Application.compile_env(:app, :app_id)
  @app_secret Application.compile_env(:app, :app_secret)
  @app_state Application.compile_env(:app, :app_state)

  @http "http%3A%2F%2Flocalhost%3A4000%2Fauth%2Ffacebook%2Fcallback"
  @url_http_exchange "https://graph.facebook.com/v15.0/oauth/access_token?client_id=#{@app_id}&client_secret=#{@app_secret}&code=code&redirect_uri=#{@http}&state=#{@app_state}"

  def get!(@url_http_exchange) do
    %{
      host: "localhost",
      port: 4000,
      body: Jason.encode!(%{"access_token" => "AT", "token_type" => "bearer"})
    }
  end

  @url_data "https://graph.facebook.com/debug_token?access_token=#{@app_id}%7C#{@app_secret}&input_token=AT"

  def get!(@url_data) do
    %{
      body:
        Jason.encode!(%{
          access_token: "AT",
          data: %{"app_id" => "1234", "is_valid" => "true"}
        })
    }
  end

  @url_data_wrong "https://graph.facebook.com/debug_token?access_token=#{@app_id}%7C#{@app_secret}&input_token=A"

  def get!(@url_data_wrong),
    do: %{
      body:
        Jason.encode!(%{
          access_token: "A",
          data: %{"is_valid" => nil}
        })
    }

  def get!("https://graph.facebook.com/v15.0/me?fields=id,email,name,picture&access_token=AT") do
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
