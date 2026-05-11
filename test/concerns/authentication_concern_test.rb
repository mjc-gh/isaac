# frozen_string_literal: true

require "test_helper"

class AuthenticationConcernTest < ActionDispatch::IntegrationTest
  test "coverage for authentication concern lines" do
    user = users(:alice)

    # Test line 11: User.find_by when session has valid id
    token = user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)
    assert_equal user.id, session[:user_id]

    # Test line 15: current_user.present? when true
    get new_users_session_url
    assert_response :success

    # Test sign out
    delete users_session_url(user.id)
    assert_nil session[:user_id]

    # Test line 15: current_user.present? when false
    get new_users_session_url
    assert_response :success
  end
end
