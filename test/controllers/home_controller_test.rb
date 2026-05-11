# frozen_string_literal: true

require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
  end

  test "should redirect unauthenticated user to login page" do
    get root_url

    assert_redirected_to new_users_session_path
  end

  test "should redirect authenticated user to dashboards" do
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    get root_url

    assert_redirected_to dashboards_url
  end
end
