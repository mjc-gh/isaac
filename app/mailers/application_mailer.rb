# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: Environ["SMTP_USER_NAME"]

  layout "mailer"
end
