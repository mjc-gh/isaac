# frozen_string_literal: true

require "test_helper"

class GoogleCalendarServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
  end

  test "initializes with a user" do
    service = GoogleCalendarService.new(@user)
    assert_equal @user, service.instance_variable_get(:@user)
  end

  test "list_calendars raises custom exception when no Google token found" do
    user_without_token = User.create!(email: "test@example.com", first_name: "Test", last_name: "User")
    service = GoogleCalendarService.new(user_without_token)

    assert_raises GoogleCalendarTokenError do
      service.list_calendars
    end
  end

  test "find_google_auth_token returns google_oauth2 token" do
    service = GoogleCalendarService.new(@user)
    token = service.send(:find_google_auth_token)

    assert token.present?
    assert_equal "google_oauth2", token.provider
  end

  test "find_google_auth_token returns nil when no google token exists" do
    user_without_token = User.create!(email: "test@example.com", first_name: "Test", last_name: "User")
    service = GoogleCalendarService.new(user_without_token)

    token = service.send(:find_google_auth_token)
    assert_nil token
  end

  test "token_expired returns false when expires_at is nil" do
    service = GoogleCalendarService.new(@user)
    token = Signet::OAuth2::Client.new(access_token: "test_token")

    is_expired = service.send(:token_expired?, token)
    assert_equal false, is_expired
  end

  test "token_expired returns false when token not yet expired" do
    service = GoogleCalendarService.new(@user)
    token = Signet::OAuth2::Client.new(access_token: "test_token")
    token.instance_variable_set(:@expires_at, Time.now + 1.hour)

    is_expired = service.send(:token_expired?, token)
    assert_equal false, is_expired
  end

  test "token_expired returns true when token is expired" do
    service = GoogleCalendarService.new(@user)
    token = Signet::OAuth2::Client.new(access_token: "test_token")
    token.instance_variable_set(:@expires_at, Time.now - 1.hour)

    is_expired = service.send(:token_expired?, token)
    assert_equal true, is_expired
  end

  test "get_valid_oauth_client returns token when not expired" do
    auth_token = auth_tokens(:alice_google)
    service = GoogleCalendarService.new(@user)
    token = Signet::OAuth2::Client.new(access_token: "test_token")
    token.instance_variable_set(:@expires_at, Time.now + 1.hour)

    service.stub :token_expired?, false do
      result = service.send(:get_valid_oauth_client, auth_token)
      assert result.is_a?(Signet::OAuth2::Client)
    end
  end

  test "get_valid_oauth_client raises when expired and no refresh token" do
    auth_token = AuthToken.new(
      user: @user,
      provider: "google",
      access_token: "test_access_token"
    )
    service = GoogleCalendarService.new(@user)
    token = Signet::OAuth2::Client.new(access_token: "test_token")
    token.instance_variable_set(:@expires_at, Time.now - 1.hour)

    service.stub :token_expired?, true do
      error = assert_raises GoogleCalendarTokenError do
        service.send(:get_valid_oauth_client, auth_token)
      end
      assert_match /Access token expired and no refresh token available/, error.message
    end
  end

  test "get_valid_oauth_client refreshes when expired and refresh token present" do
    service = GoogleCalendarService.new(@user)
    token = Signet::OAuth2::Client.new(access_token: "test_token")
    token.instance_variable_set(:@expires_at, Time.now - 1.hour)

    mock_token = Minitest::Mock.new
    mock_token.expect(:refresh!, nil)

    service.stub :token_expired?, true do
      Signet::OAuth2::Client.stub :new, mock_token do
        Environ.stub(:[], "test_value") do
          result = service.send(:get_valid_oauth_client, auth_tokens(:alice_google))
          assert result
        end
      end
    end
  end

  test "refresh_and_get_client raises custom exception on refresh failure" do
    service = GoogleCalendarService.new(@user)

    Environ.stub(:[], "test_value") do
      Signet::OAuth2::Client.stub :new, lambda { |_params|
        raise StandardError.new("Network error")
      } do
        error = assert_raises GoogleCalendarTokenError do
          service.send(:refresh_and_get_client, auth_tokens(:alice_google))
        end
        assert_match /Failed to refresh access token/, error.message
      end
    end
  end

  test "calendar_hash returns correct structure" do
    service = GoogleCalendarService.new(@user)

    mock_calendar = Minitest::Mock.new
    mock_calendar.expect(:id, "cal_123")
    mock_calendar.expect(:summary, "Work")
    mock_calendar.expect(:primary, false)

    hash = service.send(:calendar_hash, mock_calendar)

    assert_equal "cal_123", hash[:id]
    assert_equal "Work", hash[:summary]
    assert_equal false, hash[:primary]
  end

  test "oauth_client_id returns from Environ" do
    service = GoogleCalendarService.new(@user)

    Environ.stub(:[], "test_client_id") do
      client_id = service.send(:oauth_client_id)
      assert_equal "test_client_id", client_id
    end
  end

  test "oauth_client_secret returns from Environ" do
    service = GoogleCalendarService.new(@user)

    Environ.stub(:[], "test_client_secret") do
      secret = service.send(:oauth_client_secret)
      assert_equal "test_client_secret", secret
    end
  end

  test "list_calendars returns array of calendars when token is valid" do
    service = GoogleCalendarService.new(@user)

    # Mock the Google Calendar API service
    mock_calendar_service = Minitest::Mock.new
    mock_response = Minitest::Mock.new
    mock_calendar = Minitest::Mock.new

    mock_calendar.expect(:id, "calendar_id_123")
    mock_calendar.expect(:summary, "My Calendar")
    mock_calendar.expect(:primary, true)

    mock_response.expect(:items, [mock_calendar])
    mock_calendar_service.expect(:authorization=, nil, [Signet::OAuth2::Client])
    mock_calendar_service.expect(:list_calendar_lists, mock_response)

    Google::Apis::CalendarV3::CalendarService.stub :new, mock_calendar_service do
      calendars = service.list_calendars

      assert calendars.is_a?(Array)
      assert_equal 1, calendars.length
      assert_equal "calendar_id_123", calendars[0][:id]
      assert_equal "My Calendar", calendars[0][:summary]
      assert_equal true, calendars[0][:primary]
    end
  end
end
