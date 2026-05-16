# frozen_string_literal: true

require "test_helper"

class Users::CalendarPreferencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    @auth_token = auth_tokens(:alice_google)
  end

  test "edit requires authentication" do
    get edit_users_calendar_preferences_url

    assert_redirected_to new_users_session_url
  end

  test "edit requires Google token" do
    user = users(:charlie)
    post users_sessions_url, params: { email: user.email }
    token = user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    get edit_users_calendar_preferences_url

    assert_redirected_to users_auth_tokens_url
    assert_match I18n.t("calendar_preferences.no_google_token"), flash[:alert]
  end

  test "edit displays calendar selection form when calendars fetched successfully" do
    post users_sessions_url, params: { email: @user.email }
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    mock_service = Minitest::Mock.new
    mock_service.expect(:list_calendars, [{ id: "primary", summary: "Personal Calendar", primary: true }])

    GoogleCalendarService.stub :new, mock_service do
      get edit_users_calendar_preferences_url

      assert_response :success
      assert_select "h1", "Calendar Preferences"
      assert_select "option", { text: "Personal Calendar" }
    end
  end

  test "edit shows no calendars message when list is empty" do
    post users_sessions_url, params: { email: @user.email }
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    mock_service = Minitest::Mock.new
    mock_service.expect(:list_calendars, [])

    GoogleCalendarService.stub :new, mock_service do
      get edit_users_calendar_preferences_url

      assert_response :success
      assert_select "p", text: I18n.t("calendar_preferences.no_calendars")
    end
  end

  test "edit handles calendar fetch errors gracefully" do
    post users_sessions_url, params: { email: @user.email }
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    # Stub GoogleCalendarService to raise an error
    GoogleCalendarService.stub :new, lambda { |_user|
      service = Minitest::Mock.new
      service.expect(:list_calendars) { raise StandardError.new("Service error") }
      service
    } do
      get edit_users_calendar_preferences_url

      assert_response :success
      assert_select "p", text: I18n.t("calendar_preferences.no_calendars")
    end
  end

  test "update saves calendar preference" do
    post users_sessions_url, params: { email: @user.email }
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    assert_nil @user.primary_calendar_id

    patch users_calendar_preferences_path, params: { calendar_id: "calendar_123" }

    @user.reload
    assert_equal "calendar_123", @user.primary_calendar_id
    assert_redirected_to users_auth_tokens_url
    assert_match I18n.t("calendar_preferences.updated"), flash[:notice]
  end

  test "update requires authentication" do
    patch users_calendar_preferences_path, params: { calendar_id: "calendar_123" }

    assert_redirected_to new_users_session_url
  end

  test "update requires Google token" do
    user = users(:charlie)
    post users_sessions_url, params: { email: user.email }
    token = user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    patch users_calendar_preferences_path, params: { calendar_id: "calendar_123" }

    assert_redirected_to users_auth_tokens_url
    assert_match I18n.t("calendar_preferences.no_google_token"), flash[:alert]
  end
end
