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



  test "get_valid_oauth_client returns token when not expired" do
    auth_token = auth_tokens(:alice_google)
    service = GoogleCalendarService.new(@user)

    result = service.send(:get_valid_oauth_client, auth_token)
    assert result.is_a?(Signet::OAuth2::Client)
    assert_equal "google_access_token_alice", result.access_token
  end

  test "get_valid_oauth_client raises when expired and no refresh token" do
    auth_token = AuthToken.new(
      user: @user,
      provider: "google_oauth2",
      access_token: "test_access_token",
      expires_at: 1.day.ago
    )
    service = GoogleCalendarService.new(@user)

    error = assert_raises GoogleCalendarTokenError do
      service.send(:get_valid_oauth_client, auth_token)
    end
    assert_match /Access token expired and no refresh token available/, error.message
  end

  test "get_valid_oauth_client refreshes when expired and refresh token present" do
    # Create a separate user to avoid provider uniqueness constraint
    user_for_refresh = User.create!(email: "refresh_test@example.com", first_name: "Refresh", last_name: "User")
    auth_token = AuthToken.create!(
      user: user_for_refresh,
      provider: "google_oauth2",
      access_token: "test_access_token",
      refresh_token: "test_refresh_token",
      expires_at: 1.day.ago
    )
    service = GoogleCalendarService.new(user_for_refresh)

    mock_token = Minitest::Mock.new
    mock_token.expect(:refresh!, nil)

    Signet::OAuth2::Client.stub :new, mock_token do
      Environ.stub(:[], "test_value") do
        result = service.send(:get_valid_oauth_client, auth_token)
        assert result
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

    hash = GoogleCalendarService.calendar_hash(mock_calendar)

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

  test "refresh_and_get_client successfully refreshes token" do
    user_for_refresh = User.create!(email: "refresh_success@example.com", first_name: "Refresh", last_name: "Success")
    auth_token = AuthToken.create!(
      user: user_for_refresh,
      provider: "google_oauth2",
      access_token: "test_access_token",
      refresh_token: "test_refresh_token",
      expires_at: 1.day.ago
    )
    service = GoogleCalendarService.new(user_for_refresh)

    mock_token = Minitest::Mock.new
    mock_token.expect(:refresh!, nil)

    Signet::OAuth2::Client.stub :new, mock_token do
      Environ.stub(:[], "test_value") do
        result = service.send(:refresh_and_get_client, auth_token)
        assert_mock(mock_token)
      end
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

  test "event_hash returns correct structure" do
    mock_event = Minitest::Mock.new
    mock_start = Minitest::Mock.new
    mock_end = Minitest::Mock.new

    start_time = Time.now
    end_time = start_time + 1.hour

    mock_start.expect(:date_time, start_time)
    mock_end.expect(:date_time, end_time)

    mock_event.expect(:id, "event_123")
    mock_event.expect(:summary, "Meeting")
    mock_event.expect(:description, "Team sync")
    mock_event.expect(:start, mock_start)
    mock_event.expect(:end, mock_end)
    mock_event.expect(:status, "confirmed")
    mock_event.expect(:location, "Room 1")
    mock_event.expect(:created, start_time)
    mock_event.expect(:html_link, "https://calendar.google.com/event")

    hash = GoogleCalendarService.event_hash(mock_event)

    assert_equal "event_123", hash[:id]
    assert_equal "Meeting", hash[:summary]
    assert_equal "Team sync", hash[:description]
    assert_equal start_time, hash[:start]
    assert_equal end_time, hash[:stop]
    assert_equal "confirmed", hash[:status]
    assert_equal "Room 1", hash[:location]
    assert_equal start_time, hash[:created]
    assert_equal "https://calendar.google.com/event", hash[:link]
  end

  test "event_hash handles nil start and end times" do
    mock_event = Minitest::Mock.new

    start_time = Time.now
    mock_event.expect(:id, "event_nil")
    mock_event.expect(:summary, "All day event")
    mock_event.expect(:description, nil)
    mock_event.expect(:start, nil)
    mock_event.expect(:end, nil)
    mock_event.expect(:status, "confirmed")
    mock_event.expect(:location, nil)
    mock_event.expect(:created, start_time)
    mock_event.expect(:html_link, "https://calendar.google.com/event_nil")

    hash = GoogleCalendarService.event_hash(mock_event)

    assert_equal "event_nil", hash[:id]
    assert_nil hash[:start]
    assert_nil hash[:stop]
  end

  test "list_events returns array of events when token is valid" do
    service = GoogleCalendarService.new(@user)

    start_time = Time.now
    end_time = start_time + 1.hour

    mock_event = Minitest::Mock.new
    mock_start = Minitest::Mock.new
    mock_end = Minitest::Mock.new

    mock_start.expect(:date_time, start_time)
    mock_end.expect(:date_time, end_time)

    mock_event.expect(:id, "event_456")
    mock_event.expect(:summary, "Standup")
    mock_event.expect(:description, nil)
    mock_event.expect(:start, mock_start)
    mock_event.expect(:end, mock_end)
    mock_event.expect(:status, "confirmed")
    mock_event.expect(:location, nil)
    mock_event.expect(:created, start_time)
    mock_event.expect(:html_link, "https://calendar.google.com/event2")

    mock_response = Minitest::Mock.new
    mock_response.expect(:items, [mock_event])

    mock_calendar_service = Class.new do
      def authorization=(token)
      end

      def list_events(calendar_id, time_min:, time_max:)
        mock_response
      end

      define_method(:get_mock_response) { mock_response }
    end.new
    mock_calendar_service.instance_variable_set(:@mock_response, mock_response)

    # Need to set up a way to access mock_response from the list_events method
    def mock_calendar_service.list_events(calendar_id, time_min:, time_max:)
      @mock_response
    end

    Google::Apis::CalendarV3::CalendarService.stub :new, mock_calendar_service do
      events = service.list_events("cal_id", start_time: start_time, stop_time: end_time)

      assert events.is_a?(Array)
      assert_equal 1, events.length
      assert_equal "event_456", events[0][:id]
      assert_equal "Standup", events[0][:summary]
    end
  end
end

