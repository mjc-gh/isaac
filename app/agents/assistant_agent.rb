# frozen_string_literal: true

class AssistantAgent < RubyLLM::Agent
  chat_model Chat
  model "google/gemini-2.5-flash-lite"

  inputs :forwarded_message
  instructions name: -> { chat.user.first_name }
end
