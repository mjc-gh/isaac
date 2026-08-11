# frozen_string_literal: true

class AssistantMailbox < ApplicationMailbox
  def process
    email = mail.from_address.try(:address)
    user = find_user_by_email(email)

    chat = AssistantAgent.new_chat(user:, forwarded_message: nil)
    response = chat.ask(decoded_mail_body)

    ReplyToMailer.threaded_email(
      to: email,
      subject: "Re: #{mail.subject}",
      body: response.content,
      message_id: mail.message_id,
    ).deliver_later
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("Email from unknown sender: #{email}")
  end

  private

  def decoded_mail_body
    mail.text_part ? mail.text_part.body.decoded : mail.body.decoded
  end

  def find_user_by_email(email)
    User.find_by(email:) || UserAlias.find_by(email:)&.user || raise(ActiveRecord::RecordNotFound)
  end
end
