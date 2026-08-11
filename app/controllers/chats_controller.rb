# frozen_string_literal: true

class ChatsController < ApplicationController
  before_action :require_authentication
  before_action :set_chat, only: :show

  def index
    @chats = current_user.chats.includes(:messages).order(updated_at: :desc)
  end

  def create
    chat = AssistantAgent.new_chat(user: current_user, forwarded_message: nil)

    redirect_to chat_path(chat)
  end

  def show
    @messages = @chat.messages.includes(:parent_tool_call, :tool_calls).order(:created_at).to_a
    @message = @chat.messages.build
  end

  private

  def set_chat
    @chat = current_user.chats.find(params[:id])
  end
end
