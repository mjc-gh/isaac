# frozen_string_literal: true

require "test_helper"

class DashboardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
  end

  test "should redirect to login when not authenticated" do
    get dashboards_url

    assert_redirected_to new_users_session_path
  end

  test "should display dashboard with user email when authenticated" do
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    get dashboards_url

    assert_response :success
    assert_select "p", text: /#{@user.email}/
  end

  test "should display connected accounts link with count when authenticated" do
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    get dashboards_url

    assert_response :success
    assert_select "a", text: /Connected Accounts \(1\)/
    assert_select "a[href=?]", users_auth_tokens_path
  end

  test "should link to new and existing chats when authenticated" do
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    get dashboards_url

    assert_select "form[action=?]", chats_path do
      assert_select "button", text: "New chat"
    end
    assert_select "a[href=?]", chats_path, text: "View existing chats"
  end
end
