# frozen_string_literal: true

class MessagesController < ApplicationController
  before_action :require_authentication

  def create
    @chat = current_user.chats.find(params[:chat_id])
    content = params.dig(:message, :content)

    return head :unprocessable_content if content.blank?

    ChatResponseJob.perform_later(@chat.id, content)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to chat_path(@chat) }
    end
  end
end
