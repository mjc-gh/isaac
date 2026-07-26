# frozen_string_literal: true

class AssistantAgent < RubyLLM::Agent
  chat_model Chat
  model "google/gemini-2.5-flash-lite"

  inputs :forwarded_message
  instructions name: -> { chat.user.first_name }

  tools CurrentDateTimeTool, RelativeDateTimeTool

  def self.with_user_tools(user:, forwarded_message:)
    chat = create!(user:, forwarded_message:)
    chat.with_tool(GoogleCalendarSearchTool.new(user), calls: :many)
    chat
  end

  def self.for_chat(chat, forwarded_message: nil)
    find(chat.id, forwarded_message:).with_tool(GoogleCalendarSearchTool.new(chat.user))
  end
end
