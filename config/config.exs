import Config
config :app, :json_library, Jason
import_config "#{config_env()}.exs"

#  change ":app" to ":elixir_auth_facebook"
config :app,
  app_id: System.get_env("FACEBOOK_APP_ID"),
  app_secret: System.get_env("FACEBOOK_APP_SECRET"),
  app_state: System.get_env("FACEBOOK_STATE"),
