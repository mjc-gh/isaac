# frozen_string_literal: true

class ApplicationMailbox < ActionMailbox::Base
  routing ->(mail) { mail.to.include?(Environ["SMTP_USER_NAME"]) } => :assistant
end
