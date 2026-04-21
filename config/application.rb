require_relative "boot"
require_relative "../lib/environ.rb"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Isaac
  class Application < Rails::Application
    config.load_defaults 8.1
    config.autoload_lib(ignore: %w[assets tasks])

    config.secret_key_base = Environ["SECRET_KEY_BASE"]

    # Disable image processing
    config.active_storage.variant_processor = :disabled
  end
end
