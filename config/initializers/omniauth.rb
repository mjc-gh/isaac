# frozen_string_literal: true

unless ENV["SKIP_OMNIAUTH"].present?
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :google_oauth2,
      Environ["ISAAC_GOOGLE_CLIENT_ID"],
      Environ["ISAAC_GOOGLE_CLIENT_SECRET"],
      scope: ["profile", "https://www.googleapis.com/auth/calendar"],
      access_type: "offline",
      prompt: "consent"
  rescue Environ::MissingEnvVar
    raise unless Rails.env.test?
  end
end

OmniAuth.config.allowed_request_methods = [:post]
OmniAuth.config.silence_get_warning = true
