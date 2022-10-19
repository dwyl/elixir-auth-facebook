defmodule MyAppWeb.FbSdkAuthController do
  use LiveMapWeb, :controller

  def handle(conn, params) do
    profile = for {k, v} <- params, into: %{}, do: {String.to_atom(k), v}
    conn
    #  ... process the profile and continue the rendering
  end
end
