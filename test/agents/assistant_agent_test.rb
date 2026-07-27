# frozen_string_literal: true

require "test_helper"

class AssistantAgentTest < ActiveSupport::TestCase
  class ChatDouble
    attr_reader :tool, :calls

    def initialize(id: nil, user: nil)
      @id = id
      @user = user
      @calls = 0
    end

    attr_reader :id, :user

    def with_tool(tool, calls: nil)
      @tool = tool
      @calls += 1 if calls == :many
      self
    end
  end

  test "with_user_tools creates a chat and adds the calendar tool" do
    user = users(:alice)
    chat = ChatDouble.new
    calendar_tool = Object.new

    AssistantAgent.stub :create!, chat do
      GoogleCalendarSearchTool.stub :new, calendar_tool do
        result = AssistantAgent.with_user_tools(user:, forwarded_message: "Hello")

        assert_same chat, result
        assert_same calendar_tool, chat.tool
        assert_equal 1, chat.calls
      end
    end
  end

  test "for_chat finds the chat and adds the calendar tool" do
    user = users(:alice)
    chat = ChatDouble.new(id: 123, user:)
    found_chat = ChatDouble.new
    calendar_tool = Object.new

    AssistantAgent.stub :find, found_chat do
      GoogleCalendarSearchTool.stub :new, calendar_tool do
        result = AssistantAgent.for_chat(chat, forwarded_message: "Continue")

        assert_same found_chat, result
        assert_same calendar_tool, found_chat.tool
        assert_equal 0, found_chat.calls
      end
    end
  end
end
