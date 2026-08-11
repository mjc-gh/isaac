# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class ChatsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    @model = models(:assistant)
    @chat = @user.chats.create!(model: @model)
    @chat.messages.create!(role: "user", content: "Plan my afternoon")
  end

  test "requires authentication" do
    get chats_url

    assert_redirected_to new_users_session_path
  end

  test "lists only the current user's chats" do
    other_chat = users(:bob).chats.create!(model: @model)
    other_chat.messages.create!(role: "user", content: "Private conversation")
    sign_in

    get chats_url

    assert_response :success
    assert_select "a[href=?]", chat_path(@chat), text: /Plan my afternoon/
    assert_select "a[href=?]", chat_path(other_chat), count: 0
  end

  test "creates a configured chat for the current user" do
    sign_in
    created_chat = @user.chats.create!(model: @model)
    agent_mock = Minitest::Mock.new
    agent_mock.expect(:new_chat, created_chat, [], user: @user, forwarded_message: nil)

    stub_const(Object, :AssistantAgent, agent_mock) do
      post chats_url
    end

    assert_mock agent_mock
    assert_redirected_to chat_path(created_chat)
  end

  test "shows a chat with its Turbo stream and composer" do
    assistant_message = @chat.messages.create!(role: "assistant")
    tool_call = assistant_message.tool_calls.create!(
      tool_call_id: "call_1",
      name: "google_calendar_search",
      arguments: { start_time: "2026-07-26T09:00:00Z" }
    )
    date_tool_call = assistant_message.tool_calls.create!(
      tool_call_id: "call_2",
      name: "current_date_time",
      arguments: {}
    )
    tool_result = @chat.messages.create!(
      role: "tool",
      content: [{ summary: "Lunch" }].to_json,
      tool_call_id: tool_call.id
    )
    date_tool_result = @chat.messages.create!(
      role: "tool",
      content: "2026-07-26T12:00:00Z",
      tool_call_id: date_tool_call.id
    )
    sign_in

    get chat_url(@chat)

    assert_response :success
    assert_select "turbo-cable-stream-source[channel='Turbo::StreamsChannel']"
    assert_select "#message_#{@chat.messages.find_by!(role: "user").id}", text: /Plan my afternoon/
    assert_select "article#message_#{assistant_message.id}" do
      assert_select "details", count: 2
      assert_select "details[open]", count: 0
      assert_select "summary", text: /Used Google calendar search/
      assert_select "summary", text: /Used Current date time/
      assert_select "pre", text: /start_time.*2026-07-26T09:00:00Z/m
    end
    assert_select "article#message_#{tool_result.id}" do
      assert_select "summary", text: /Result from Google calendar search/
      assert_select "pre", text: /summary.*Lunch/m
    end
    assert_select "article#message_#{date_tool_result.id}" do
      assert_select "summary", text: /Result from Current date time/
      assert_select "pre", text: "2026-07-26T12:00:00Z"
    end
    assert_select "form#new_message textarea[data-controller='submit-on-enter'][data-action='keydown->submit-on-enter#submit']"
  end

  test "does not show another user's chat" do
    other_chat = users(:bob).chats.create!(model: @model)
    sign_in

    get chat_url(other_chat)

    assert_response :not_found
  end

  private

  def sign_in
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)
  end
end
