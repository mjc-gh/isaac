# frozen_string_literal: true

require "test_helper"

class Users::SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
  end

  test "edit requires authentication" do
    get edit_users_settings_url

    assert_redirected_to new_users_session_url
  end

  test "edit displays timezone setting" do
    sign_in

    get edit_users_settings_url

    assert_response :success
    assert_select "h1", "Settings"
    assert_select "select[name='user[timezone]']"
    assert_select "option[value='Eastern Time (US & Canada)']"
  end

  test "update saves timezone setting" do
    sign_in

    patch users_settings_path, params: { user: { timezone: "Eastern Time (US & Canada)" } }

    assert_equal "Eastern Time (US & Canada)", @user.reload.timezone
    assert_redirected_to edit_users_settings_url
    assert_match I18n.t("settings.updated"), flash[:notice]
  end

  test "update rejects unknown timezone" do
    sign_in

    patch users_settings_path, params: { user: { timezone: "Not/A_Timezone" } }

    assert_response :unprocessable_entity
    assert_select "#error_explanation"
    assert_equal "UTC", @user.reload.timezone
  end

  test "update requires authentication" do
    patch users_settings_path, params: { user: { timezone: "UTC" } }

    assert_redirected_to new_users_session_url
  end

  private

  def sign_in
    post users_sessions_url, params: { email: @user.email }
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)
  end
end
