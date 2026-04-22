# frozen_string_literal: true

class AssistantMailbox < ApplicationMailbox
  def process
    email = mail.from.first&.downcase
    user = User.find_by!(email:)

    response = AssistantAgent.new.ask(mail.body.decoded)

    ReplyToMailer.threaded_email(
      to: email,
      subject: "Re: #{mail.subject}",
      body: response.content,
      in_reply_to: mail.message_id,
    ).deliver_later
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("Email from unknown sender: #{email}")
  end
end
