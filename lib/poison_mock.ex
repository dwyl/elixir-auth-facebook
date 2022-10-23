# defmodule App.HTTPoisonMock do
#   @cb_url if System.get_env("FACEBOOK_HTTPS") == "false",
#             do: "http%3A%2F%2Flocalhost%3A4000%2Fauth%2Ffacebook%2Fcallback",
#             else: "https%3A%2F%2Flocalhost%2Fauth%2Ffacebook%2Fcallback"

#   @app_id 1234
#   @app_secret ABCD
#   @app_state 1234

#   @url_exchange "https://graph.facebook.com/v15.0/oauth/access_token?client_id=#{@app_id}&client_secret=#{@app_secret}&code=code&redirect_uri=#{@cb_url}&state=#{@app_state}"

#   def get!(@url_exchange) do
#     %{"access_token" => "AT", "token_type" => "bearer"}
#   end

#   @url_data "https://graph.facebook.com/debug_token?access_token=#{@app_id}%7CABCD&input_token=AT"

#   def get!(@url_data) do
#     %Plug.Conn{
#       assigns: %{
#         access_token: "AT",
#         data: %{"app_id" => 1234},
#         is_valid: true
#       }
#     }
#   end

#   def get!("https://graph.facebook.com/v15.0/me?fields=id,email,name,picture&access_token=AT") do
#     IO.puts("THREE")

#     %Plug.Conn{
#       assigns: %{
#         access_token: "AT",
#         data: %{"app_id" => 1234},
#         is_valid: true,
#         profile: %{
#           "id" => 100,
#           "picture" => %{
#             "data" => %{
#               "url" => "http://dwyl.com"
#             }
#           }
#         }
#       }
#     }
#   end
# end
