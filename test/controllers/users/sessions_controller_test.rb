# frozen_string_literal: true

require "test_helper"

class Users::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
  end

  test "should get new" do
    get new_users_session_url

    assert_response :success
  end

  test "should create session and send email" do
    assert_difference("ActionMailer::Base.deliveries.size", 1) do
      perform_enqueued_jobs do
        post users_sessions_url, params: { email: @user.email }
      end
    end

    assert_redirected_to new_users_session_url
    assert_match I18n.t("sessions.magic_link_sent"), flash[:notice]
  end

  test "should send same message for non-existent user for security" do
    assert_difference("ActionMailer::Base.deliveries.size", 0) do
      post users_sessions_url, params: { email: "nonexistent@example.com" }
    end

    assert_redirected_to new_users_session_url
    assert_match I18n.t("sessions.magic_link_sent"), flash[:notice]
  end

  test "should verify valid token and sign in user" do
    token = @user.generate_magic_link_token(for: :session)

    get verify_users_sessions_url(token: token)

    assert_redirected_to root_url
    assert_match I18n.t("sessions.signed_in"), flash[:notice]
    assert_equal @user.id, session[:user_id]
  end

  test "should reject invalid token" do
    get verify_users_sessions_url(token: "invalid_token")

    assert_redirected_to new_users_session_url
    assert_match I18n.t("sessions.invalid_token"), flash[:alert]
    assert_nil session[:user_id]
  end

  test "should reject expired token" do
    token = @user.generate_magic_link_token(expires_in: -1.second, for: :session)

    get verify_users_sessions_url(token: token)

    assert_redirected_to new_users_session_url
    assert_match I18n.t("sessions.invalid_token"), flash[:alert]
    assert_nil session[:user_id]
  end

  test "should destroy session on sign out" do
    post users_sessions_url, params: { email: @user.email }
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    delete users_session_url(@user.id)

    assert_redirected_to root_url
    assert_match I18n.t("sessions.signed_out"), flash[:notice]
    assert_nil session[:user_id]
  end
end
