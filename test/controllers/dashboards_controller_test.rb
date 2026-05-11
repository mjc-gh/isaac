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
end
