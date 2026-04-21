# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: Environ["ISAAC_SENDER_ADDRESS"]

  layout "mailer"
end
