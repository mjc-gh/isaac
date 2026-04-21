# frozen_string_literal: true

class ReplyToTool < RubyLLM::Tool
  description "Sends an email reply in a threaded conversation"

  # :nocov:
  params do
    string :to, description: "Recipient email address"
    string :subject, description: "Email subject line"
    string :body, description: "Email body content"
    string :message_id, description: "Original message ID for threading (e.g., '<id@example.com>')"
  end
  # :nocov:

  def execute(to:, subject:, body:, message_id:)
    ReplyToMailer.threaded_email(to:, subject:, body:, message_id:).deliver_later

    "Email reply queued for delivery to #{to}"
  end
end
