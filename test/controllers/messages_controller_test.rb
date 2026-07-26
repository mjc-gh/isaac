# frozen_string_literal: true

require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:alice)
    @model = models(:assistant)
    @chat = @user.chats.create!(model: @model)
  end

  test "requires authentication" do
    post chat_messages_url(@chat), params: { message: { content: "Hello" } }

    assert_redirected_to new_users_session_path
  end

  test "enqueues a response and resets the Turbo composer" do
    sign_in

    assert_enqueued_with(job: ChatResponseJob, args: [@chat.id, "Hello"]) do
      post chat_messages_url(@chat),
           params: { message: { content: "Hello" } },
           as: :turbo_stream
    end

    assert_response :success
    assert_select "turbo-stream[action='replace'][target='new_message']"
    assert_select "turbo-stream[action='remove'][target='empty_chat']"
  end

  test "redirects HTML message submissions back to the chat" do
    sign_in

    post chat_messages_url(@chat), params: { message: { content: "Hello" } }

    assert_redirected_to chat_path(@chat)
  end

  test "rejects blank messages" do
    sign_in

    assert_no_enqueued_jobs do
      post chat_messages_url(@chat), params: { message: { content: " " } }
    end

    assert_response :unprocessable_content
  end

  test "does not enqueue messages for another user's chat" do
    other_chat = users(:bob).chats.create!(model: @model)
    sign_in

    assert_no_enqueued_jobs do
      post chat_messages_url(other_chat), params: { message: { content: "Hello" } }
    end

    assert_response :not_found
  end

  private

  def sign_in
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)
  end
end
