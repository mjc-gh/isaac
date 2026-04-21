# frozen_string_literal: true

# :nocov:
class AssistantAgent < RubyLLM::Agent
  chat_model Chat
  tools ReplyToTool
  instructions
end
# :nocov:
