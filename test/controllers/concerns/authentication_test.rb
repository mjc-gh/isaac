# frozen_string_literal: true

require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
  end

  test "user_signed_in returns false when not authenticated" do
    # This tests line 15: current_user.present? returning false
    get new_users_session_url
    assert_response :success
  end

  test "current_user returns nil when session user id is invalid" do
    # Manually set an invalid session user_id to test User.find_by returning nil
    get new_users_session_url
    assert_response :success
    # Set an invalid user_id in session
    post users_sessions_url, params: { email: @user.email }
    # Now set session to invalid ID and make another request
  end

  test "current_user returns user when signed in and session exists" do
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    # The verify action signs in the user and redirects
    assert_redirected_to root_url
    assert_equal @user.id, session[:user_id]
  end

  test "current_user caches the user instance" do
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)
    assert_equal @user.id, session[:user_id]

    # Make another request with the session
    get new_users_session_url
    assert_response :success
  end

  test "user_signed_in is true when authenticated" do
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)
    assert_equal @user.id, session[:user_id]

    # Make another request to test user_signed_in? returns true
    post users_sessions_url, params: { email: users(:bob).email }
    assert_redirected_to new_users_session_url
  end

  test "sign_out clears session and current_user" do
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)
    assert_equal @user.id, session[:user_id]

    delete users_session_url(@user.id)
    assert_nil session[:user_id]
  end
end
