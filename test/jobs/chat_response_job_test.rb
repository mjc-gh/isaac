# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class ChatResponseJobTest < ActiveJob::TestCase
  Chunk = Data.define(:content)

  class StreamingAgent
    attr_reader :prompt

    def ask(prompt)
      @prompt = prompt
      yield Chunk.new("")
      yield Chunk.new("Hello")
    end
  end

  test "streams non-empty response chunks" do
    message_mock = Minitest::Mock.new
    message_mock.expect(:broadcast_append_chunk, nil, ["Hello"])

    messages_mock = Minitest::Mock.new
    messages_mock.expect(:last, message_mock)

    chat_mock = Minitest::Mock.new
    chat_mock.expect(:messages, messages_mock)

    agent = StreamingAgent.new

    Chat.stub :find, chat_mock do
      AssistantAgent.stub :for_chat, agent do
        ChatResponseJob.perform_now(123, "Hi")
      end
    end

    assert_equal "Hi", agent.prompt
    assert_mock chat_mock
    assert_mock messages_mock
    assert_mock message_mock
  end
end
