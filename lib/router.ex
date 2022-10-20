# .........

scope "/auth", LiveMapWeb do
  pipe_through(:browser)

  get("/google/callback", GoogleAuthController, :index)
  get("/github/callback", GithubAuthController, :index)
  get("/facebook/callback", FacebookAuthController, :login)

  # this is the new route
  get("/fbk/sdk", FacebookSdkAuthController, :handle)
end
