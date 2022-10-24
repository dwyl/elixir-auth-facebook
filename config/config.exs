import Config

config :elixir_auth_facebook, :json_library, Jason

import_config "#{config_env()}.exs"
