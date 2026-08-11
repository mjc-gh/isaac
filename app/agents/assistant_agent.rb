# frozen_string_literal: true

class AssistantAgent < RubyLLM::Agent
  chat_model Chat
  model "google/gemini-2.5-flash-lite"

  inputs :forwarded_message
  instructions name: -> { chat.user.first_name }

  class << self
    def new_chat(user:, forwarded_message:)
      chat = create!(user:, forwarded_message:)

      with_user_tools(chat)
    end

    def for_chat(chat, forwarded_message: nil)
      found_chat = find(chat.id, forwarded_message:)

      with_user_tools(found_chat)
    end

    private

    def with_user_tools(chat)
      chat.with_tools(
        CurrentDateTimeTool.new(chat.user),
        RelativeDateTimeTool.new(chat.user),
        GoogleCalendarSearchTool.new(chat.user),
        GoogleCalendarAddEventTool.new(chat.user),
        calls: :many
      )
    end
  end
end
