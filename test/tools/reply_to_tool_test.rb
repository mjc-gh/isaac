# frozen_string_literal: true

require "test_helper"

class ReplyToToolTest < ActiveSupport::TestCase
  test "execute returns confirmation message with recipient email" do
    message = ReplyToTool.new.execute(
      to: "user@example.com",
      subject: "Re: Your question",
      body: "Here is the response",
      message_id: "<original-message-id@example.com>"
    )

    assert_equal "Email reply queued for delivery to user@example.com", message
    assert_enqueued_email_with ReplyToMailer, :threaded_email, args: [{
      to: "user@example.com",
      subject: "Re: Your question",
      body: "Here is the response",
      message_id: "<original-message-id@example.com>"
    }]
  end
end
