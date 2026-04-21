# frozen_string_literal: true

class AssistantMailbox < ApplicationMailbox
  def process
    user = User.find_by(email: mail.from.first&.downcase)

    unless user
      Rails.logger.warn("Email from unknown sender: #{mail.from.first}")
      return
    end

    AssistantAgent.new.ask(mail.body.decoded)
  end
end
