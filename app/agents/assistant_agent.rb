# frozen_string_literal: true

class AssistantAgent < RubyLLM::Agent
  chat_model Chat
  tools ReplyToTool
  instructions
end
