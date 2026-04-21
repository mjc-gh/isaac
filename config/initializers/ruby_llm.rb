RubyLLM.configure do |config|
  # Set API key
  config.openrouter_api_key = Environ["ISAAC_OPENROUTER_API_KEY"]

  config.default_model = "google/gemma-3-12b-it:free"

  # Use the new association-based acts_as API (recommended)
  config.use_new_acts_as = true
end
