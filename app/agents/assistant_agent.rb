# frozen_string_literal: true

class AssistantAgent < RubyLLM::Agent
  chat_model Chat
  model "google/gemini-2.5-flash-lite"

  inputs :forwarded_message
  instructions name: -> { chat.user.first_name }

  tools CurrentDateTimeTool, RelativeDateTimeTool

  def self.with_user_tools(user:, forwarded_message:)
    chat = create!(user:, forwarded_message:)
    chat.with_tool(GoogleCalendarSearchTool.new(user))
    chat
  end
end
