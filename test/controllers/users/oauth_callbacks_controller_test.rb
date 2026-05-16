# frozen_string_literal: true

require "test_helper"

class Users::OauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.test_mode = false
  end

  test "create requires authentication" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      credentials: {
        token: "test_access_token",
        refresh_token: "test_refresh_token"
      }
    )

    get "/auth/google_oauth2/callback"

    assert_redirected_to new_users_session_url
    assert_match I18n.t("sessions.unauthenticated"), flash[:alert]
  end

  test "create saves auth token with access_token and refresh_token" do
    user = users(:charlie)
    post users_sessions_url, params: { email: user.email }
    token = user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      credentials: {
        token: "test_access_token",
        refresh_token: "test_refresh_token"
      }
    )

    assert_difference("AuthToken.count", 1) do
      get "/auth/google_oauth2/callback"
    end

    assert_redirected_to users_auth_tokens_url
    assert_match I18n.t("auth_tokens.connected"), flash[:notice]

    auth_token = user.auth_tokens.last
    assert_equal "google_oauth2", auth_token.provider
    assert_equal "test_access_token", auth_token.access_token
    assert_equal "test_refresh_token", auth_token.refresh_token
  end

  test "create updates existing auth token with new credentials" do
    post users_sessions_url, params: { email: @user.email }
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    # Create initial token
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      credentials: {
        token: "first_access_token",
        refresh_token: "first_refresh_token"
      }
    )
    get "/auth/google_oauth2/callback"

    initial_token_id = @user.auth_tokens.find_by(provider: "google_oauth2").id

    # Update token
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      credentials: {
        token: "new_access_token",
        refresh_token: "new_refresh_token"
      }
    )

    assert_no_difference("AuthToken.count") do
      get "/auth/google_oauth2/callback"
    end

    auth_token = @user.auth_tokens.find(initial_token_id)
    assert_equal "new_access_token", auth_token.access_token
    assert_equal "new_refresh_token", auth_token.refresh_token
  end

  test "failure redirects with error message" do
    post users_sessions_url, params: { email: @user.email }
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    get users_auth_failure_path(message: "access_denied")

    assert_redirected_to users_auth_tokens_url
    assert_match I18n.t("auth_tokens.failure"), flash[:alert]
  end

  test "create with invalid credentials shows error" do
    post users_sessions_url, params: { email: @user.email }
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    # Simulate missing access_token (will fail validation)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      credentials: {
        token: nil,
        refresh_token: "test_refresh_token"
      }
    )

    get "/auth/google_oauth2/callback"

    assert_redirected_to users_auth_tokens_url
    assert_match I18n.t("auth_tokens.failure"), flash[:alert]
  end

  test "create without expires_at in credentials sets default expiration" do
    user = users(:charlie)
    post users_sessions_url, params: { email: user.email }
    token = user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      credentials: {
        token: "test_access_token",
        refresh_token: "test_refresh_token"
        # no expires_at provided
      }
    )

    get "/auth/google_oauth2/callback"

    assert_redirected_to users_auth_tokens_url
    auth_token = user.auth_tokens.find_by(provider: "google_oauth2")
    assert auth_token.expires_at.present?
    # Should be approximately 1 year from now
    assert (auth_token.expires_at - 1.year.from_now).abs < 60 # within 60 seconds
  end
end
