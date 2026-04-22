# frozen_string_literal: true

class ReplyToMailer < ApplicationMailer
  def threaded_email(to:, subject:, body:, message_id:)
    @body = body

    mail(
      to: to,
      subject: subject,
      in_reply_to: message_id
    )
  end
end
