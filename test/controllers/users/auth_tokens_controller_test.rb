# frozen_string_literal: true

require "test_helper"

class Users::AuthTokensControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    @auth_token = auth_tokens(:alice_google)
    @bob_auth_token = auth_tokens(:bob_github)
  end

  test "index requires authentication" do
    get users_auth_tokens_url

    assert_redirected_to new_users_session_url
    assert_match I18n.t("sessions.unauthenticated"), flash[:alert]
  end

  test "index displays user's connected accounts when authenticated" do
    post users_sessions_url, params: { email: @user.email }
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    get users_auth_tokens_url

    assert_response :success
    assert_select "h1", "Connected Accounts"
    assert_select "table tbody tr", count: 1
    assert_select "table tbody tr td", text: "Google"
  end

  test "index shows message when no connected accounts" do
    post users_sessions_url, params: { email: users(:charlie).email }
    token = users(:charlie).generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    get users_auth_tokens_url

    assert_response :success
    assert_select "p", text: "You don't have any connected accounts yet."
  end

  test "destroy requires authentication" do
    delete users_auth_token_path(@auth_token)

    assert_redirected_to new_users_session_url
  end

  test "destroy removes auth token for current user" do
    post users_sessions_url, params: { email: @user.email }
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    assert_difference("AuthToken.count", -1) do
      delete users_auth_token_path(@auth_token)
    end

    assert_redirected_to users_auth_tokens_url
    assert_match I18n.t("auth_tokens.disconnected"), flash[:notice]
  end

  test "user cannot delete another user's auth token" do
    post users_sessions_url, params: { email: @user.email }
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    delete users_auth_token_path(@bob_auth_token)

    assert_response :not_found
  end
end
