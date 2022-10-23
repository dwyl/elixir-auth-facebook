import Config
config :app, :json_library, Jason
import_config "#{config_env()}.exs"

#  EXAMPLE
config :elixir_auth_facebook,
  app_id: System.get_env("FACEBOOK_APP_ID"),
  app_secret: System.get_env("FACEBOOK_APP_SECRET"),
  app_state: System.get_env("FACEBOOK_STATE"),
  https: true
