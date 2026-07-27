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

  test "should display account stat cards with current user's counts" do
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    get dashboards_url

    assert_response :success
    assert_select "nav[aria-label=?]", "Account" do
      assert_select "a[href=?]", users_aliases_path, count: 1 do
        assert_select "span", text: "Aliases"
        assert_select "span", text: "2"
      end
      assert_select "a[href=?]", users_auth_tokens_path, count: 1 do
        assert_select "span", text: "Connected Accounts"
        assert_select "span", text: "1"
      end
    end
  end

  test "should display navigable zero-count account stat cards" do
    token = users(:charlie).generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    get dashboards_url

    assert_response :success
    assert_select "nav[aria-label=?]", "Account" do
      assert_select "a[href=?]", users_aliases_path, count: 1 do
        assert_select "span", text: "Aliases"
        assert_select "span", text: "0"
      end
      assert_select "a[href=?]", users_auth_tokens_path, count: 1 do
        assert_select "span", text: "Connected Accounts"
        assert_select "span", text: "0"
      end
    end
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
