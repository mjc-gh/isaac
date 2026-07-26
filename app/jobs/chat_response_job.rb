# frozen_string_literal: true

class ChatResponseJob < ApplicationJob
  def perform(chat_id, content)
    chat = Chat.find(chat_id)
    agent = AssistantAgent.for_chat(chat)

    agent.ask(content) do |chunk|
      next if chunk.content.blank?

      chat.messages.last.broadcast_append_chunk(chunk.content)
    end
  end
end
