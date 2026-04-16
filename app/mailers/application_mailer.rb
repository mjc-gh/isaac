# frozen_string_literal: true

# :nocov:
class ApplicationMailer < ActionMailer::Base
  default from: Environ["SMTP_USER_NAME"]

  layout "mailer"
end
# :nocov:
