# frozen_string_literal: true

class ChatsController < ApplicationController
  before_action :require_authentication
  before_action :set_chat, only: :show

  def index
    @chats = current_user.chats.includes(:messages).order(updated_at: :desc)
  end

  def create
    chat = AssistantAgent.with_user_tools(user: current_user, forwarded_message: nil)

    redirect_to chat_path(chat)
  end

  def show
    @message = @chat.messages.build
  end

  private

  def set_chat
    @chat = current_user.chats.find(params[:id])
  end
end
