# frozen_string_literal: true

require "test_helper"

class ReplyToMailerTest < ActionMailer::TestCase
  test "threaded_email sends to correct recipient" do
    mail = ReplyToMailer.threaded_email(
      to: "user@example.com",
      subject: "Re: Your question",
      body: "Here is the response",
      message_id: "<original-message-id@example.com>"
    )

    assert_equal ["user@example.com"], mail.to
  end

  test "threaded_email sets subject correctly" do
    mail = ReplyToMailer.threaded_email(
      to: "user@example.com",
      subject: "Re: Your question",
      body: "Here is the response",
      message_id: "<original-message-id@example.com>"
    )

    assert_equal "Re: Your question", mail.subject
  end

  test "threaded_email includes body content" do
    mail = ReplyToMailer.threaded_email(
      to: "user@example.com",
      subject: "Re: Your question",
      body: "Here is the response to your inquiry",
      message_id: "<original-message-id@example.com>"
    )

    assert_match "Here is the response to your inquiry", mail.body.encoded
  end

  test "threaded_email sets In-Reply-To header" do
    message_id = "<original-message-id@example.com>"
    mail = ReplyToMailer.threaded_email(
      to: "user@example.com",
      subject: "Re: Your question",
      body: "Here is the response",
      message_id: message_id
    )

    assert_equal message_id, mail.header["In-Reply-To"].value
  end

  test "threaded_email sets References header" do
    message_id = "<original-message-id@example.com>"
    mail = ReplyToMailer.threaded_email(
      to: "user@example.com",
      subject: "Re: Your question",
      body: "Here is the response",
      message_id: message_id
    )

    assert_equal message_id, mail.header["References"].value
  end
end
