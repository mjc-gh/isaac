# frozen_string_literal: true

require "test_helper"

class AssistantAgentTest < ActiveSupport::TestCase
  class ChatDouble
    attr_reader :tools, :calls

    def initialize(id: nil, user: nil)
      @id = id
      @user = user
      @tools = []
      @calls = []
    end

    attr_reader :id, :user

    def with_tools(*tools, calls: nil)
      @tools.concat tools
      @calls << calls
      self
    end
  end

  test "new_chat creates a chat and adds both calendar tools" do
    user = users(:alice)
    chat = ChatDouble.new
    search_tool = Object.new
    add_event_tool = Object.new

    AssistantAgent.stub :create!, chat do
      GoogleCalendarSearchTool.stub :new, search_tool do
        GoogleCalendarAddEventTool.stub :new, add_event_tool do
          result = AssistantAgent.new_chat(user:, forwarded_message: "Hello")

          assert_same chat, result
          assert_includes chat.tools, search_tool
          assert_includes chat.tools, add_event_tool
          assert_equal [:many], chat.calls
        end
      end
    end
  end

  test "for_chat finds the chat and adds both calendar tools" do
    user = users(:alice)
    chat = ChatDouble.new(id: 123, user:)
    found_chat = ChatDouble.new
    search_tool = Object.new
    add_event_tool = Object.new

    AssistantAgent.stub :find, found_chat do
      GoogleCalendarSearchTool.stub :new, search_tool do
        GoogleCalendarAddEventTool.stub :new, add_event_tool do
          result = AssistantAgent.for_chat(chat, forwarded_message: "Continue")

          assert_same found_chat, result
          assert_includes found_chat.tools, search_tool
          assert_includes found_chat.tools, add_event_tool
          assert_equal [:many], found_chat.calls
        end
      end
    end
  end
end
