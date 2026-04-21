# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class AssistantMailboxTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
  end

  test "calls assistant agent for known user" do
    mail_message = Mail.new(
      to: "assistant@example.com",
      from: @user.email,
      subject: "Test",
      body: "Test email body"
    )

    inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(mail_message.to_s)
    mailbox = AssistantMailbox.new(inbound_email)

    # Mock AssistantAgent instance and class
    agent_instance_mock = Minitest::Mock.new
    agent_instance_mock.expect(:ask, nil, [/Test email body/])

    AssistantAgent.stub :new, agent_instance_mock do
      mailbox.process

      assert_mock(agent_instance_mock)
    end
  end

  test "logs warning and returns for unknown sender" do
    unknown_email = "unknown@example.com"
    mail_message = Mail.new(
      to: "assistant@example.com",
      from: unknown_email,
      subject: "Test",
      body: "Test email"
    )

    inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(mail_message.to_s)
    mailbox = AssistantMailbox.new(inbound_email)

    # Mock Rails.logger to verify warning is logged
    logger_mock = Minitest::Mock.new
    logger_mock.expect(:warn, nil, ["Email from unknown sender: #{unknown_email}"])

    original_logger = Rails.logger
    Rails.logger = logger_mock

    begin
      mailbox.process

      # Verify the mock was called as expected
      assert_mock(logger_mock)
    ensure
      Rails.logger = original_logger
    end
  end
end
