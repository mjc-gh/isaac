# frozen_string_literal: true

class AssistantMailbox < ApplicationMailbox
  def process
    email = mail.from_address.try(:address)
    user = find_user_by_email(email)

    chat = AssistantAgent.with_user_tools(user:, forwarded_message: nil)
    response = chat.ask(mail.body.decoded)

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

  def find_user_by_email(email)
    User.find_by(email:) || UserAlias.find_by(email:)&.user || raise(ActiveRecord::RecordNotFound)
  end
end
