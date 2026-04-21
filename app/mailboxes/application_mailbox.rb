# frozen_string_literal: true

# :nocov:
class ApplicationMailbox < ActionMailbox::Base
  routing ->(mail) { mail.to.include?(Environ["SMTP_USER_NAME"]) } => :assistant
end
# :nocov:
