RubyLLM.configure do |config|
  # Set API key
  config.openrouter_api_key = ENV.fetch(
    "OPENROUTER_API_KEY",
    Rails.application.credentials.dig(:openrouter_api_key)
  )

  config.default_model = "google/gemma-3-12b-it:free"

  # Use the new association-based acts_as API (recommended)
  config.use_new_acts_as = true
end
