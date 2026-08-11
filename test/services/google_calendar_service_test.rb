# frozen_string_literal: true

require "test_helper"

class GoogleCalendarServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @service = GoogleCalendarService.new(@user)
  end

  test "list_calendars raises when the user has no Google token" do
    @user.auth_tokens.destroy_all

    error = assert_raises(GoogleCalendarTokenError) { @service.list_calendars }

    assert_equal "No Google auth token found", error.message
  end

  test "list_calendars authorizes the API and maps its response" do
    response = Google::Apis::CalendarV3::CalendarList.new(
      items: [
        Google::Apis::CalendarV3::CalendarListEntry.new(
          id: "calendar_id_123",
          summary: "My Calendar",
          primary: true
        )
      ]
    )
    calendar_api = Minitest::Mock.new
    calendar_api.expect(:authorization=, nil) do |token|
      token.is_a?(Signet::OAuth2::Client) && token.access_token == "google_access_token_alice"
    end
    calendar_api.expect(:list_calendar_lists, response)

    Google::Apis::CalendarV3::CalendarService.stub(:new, calendar_api) do
      assert_equal [{ id: "calendar_id_123", summary: "My Calendar", primary: true }], @service.list_calendars
    end

    assert_mock calendar_api
  end

  test "list_events passes filters, maps real API events, and sorts newest first" do
    earlier_start = Time.zone.parse("2026-07-26 09:00:00")
    later_start = Time.zone.parse("2026-07-26 11:00:00")
    earlier_event = google_event(
      id: "earlier",
      summary: "Planning",
      start_time: earlier_start,
      stop_time: earlier_start + 1.hour
    )
    later_event = google_event(
      id: "later",
      summary: "Standup",
      start_time: later_start,
      stop_time: later_start + 30.minutes,
      description: "Team sync",
      location: "Room 1"
    )
    response = Google::Apis::CalendarV3::Events.new(items: [earlier_event, later_event])
    calendar_api = Minitest::Mock.new
    calendar_api.expect(:authorization=, nil, [Signet::OAuth2::Client])
    calendar_api.expect(
      :list_events,
      response,
      ["calendar_id"],
      time_min: earlier_start.iso8601,
      time_max: (later_start + 1.hour).iso8601,
      q: "team"
    )

    Google::Apis::CalendarV3::CalendarService.stub(:new, calendar_api) do
      events = @service.list_events(
        "calendar_id",
        start_time: earlier_start,
        stop_time: later_start + 1.hour,
        search_query: "team"
      )

      assert_equal %w[later earlier], events.pluck(:id)
      assert_equal(
        {
          id: "later",
          summary: "Standup",
          description: "Team sync",
          start: later_start,
          stop: later_start + 30.minutes,
          status: "confirmed",
          location: "Room 1",
          created: later_start - 1.day,
          link: "https://calendar.google.com/calendar/event?eid=later"
        },
        events.first
      )
    end

    assert_mock calendar_api
  end

  test "list_events omits a blank search query" do
    start_time = Time.zone.parse("2026-07-26 09:00:00")
    response = Google::Apis::CalendarV3::Events.new(items: [])
    calendar_api = Minitest::Mock.new
    calendar_api.expect(:authorization=, nil, [Signet::OAuth2::Client])
    calendar_api.expect(
      :list_events,
      response,
      ["calendar_id"],
      time_min: start_time.iso8601,
      time_max: (start_time + 1.hour).iso8601
    )

    Google::Apis::CalendarV3::CalendarService.stub(:new, calendar_api) do
      assert_empty @service.list_events(
        "calendar_id",
        start_time: start_time,
        stop_time: start_time + 1.hour,
        search_query: ""
      )
    end

    assert_mock calendar_api
  end

  test "add_event authorizes, inserts an event, and normalizes the response" do
    start_time = Time.zone.parse("2026-07-27 09:00:00")
    stop_time = start_time + 1.hour
    response = google_event(
      id: "created",
      summary: "Planning",
      start_time:,
      stop_time:,
      description: "Discuss the upcoming release"
    )
    calendar_api = Minitest::Mock.new
    calendar_api.expect(:authorization=, nil, [Signet::OAuth2::Client])
    calendar_api.expect(:insert_event, response) do |calendar_id, event|
      calendar_id == "calendar_id" && event.is_a?(Google::Apis::CalendarV3::Event) &&
        event.summary == "Planning" && event.description == "Discuss the upcoming release" &&
        event.start.date_time == start_time && event.end.date_time == stop_time
    end

    Google::Apis::CalendarV3::CalendarService.stub(:new, calendar_api) do
      assert_equal(
        {
          id: "created",
          summary: "Planning",
          description: "Discuss the upcoming release",
          start: start_time,
          stop: stop_time,
          status: "confirmed",
          location: nil,
          created: start_time - 1.day,
          link: "https://calendar.google.com/calendar/event?eid=created"
        },
        @service.add_event(
          "calendar_id",
          title: "Planning",
          start_time:,
          stop_time:,
          description: "Discuss the upcoming release"
        )
      )
    end

    assert_mock calendar_api
  end

  test "event_hash handles missing event times" do
    event = Google::Apis::CalendarV3::Event.new(
      id: "cancelled_event",
      summary: "Cancelled event",
      status: "cancelled"
    )

    assert_equal(
      {
        id: "cancelled_event",
        summary: "Cancelled event",
        description: nil,
        start: nil,
        stop: nil,
        status: "cancelled",
        location: nil,
        created: nil,
        link: nil
      },
      GoogleCalendarService.event_hash(event)
    )
  end

  test "list_calendars raises when an expired token cannot be refreshed" do
    auth_tokens(:alice_google).update!(expires_at: 1.day.ago, refresh_token: nil)

    error = assert_raises(GoogleCalendarTokenError) { @service.list_calendars }

    assert_equal "Access token expired and no refresh token available", error.message
  end

  test "list_calendars refreshes an expired token" do
    auth_token = auth_tokens(:alice_google)
    auth_token.update!(expires_at: 1.day.ago)
    refreshed_client = Minitest::Mock.new
    refreshed_client.expect(:refresh!, nil)
    constructor_calls = []
    original_constructor = Signet::OAuth2::Client.method(:new)
    client_constructor = lambda do |**options|
      constructor_calls << options
      options.key?(:access_token) ? original_constructor.call(**options) : refreshed_client
    end
    response = Google::Apis::CalendarV3::CalendarList.new(items: [])
    calendar_api = Minitest::Mock.new
    calendar_api.expect(:authorization=, nil, [refreshed_client])
    calendar_api.expect(:list_calendar_lists, response)
    credentials = {
      "ISAAC_GOOGLE_CLIENT_ID" => "client_id",
      "ISAAC_GOOGLE_CLIENT_SECRET" => "client_secret"
    }

    Signet::OAuth2::Client.stub(:new, client_constructor) do
      Environ.stub(:[], ->(key) { credentials.fetch(key) }) do
        Google::Apis::CalendarV3::CalendarService.stub(:new, calendar_api) do
          assert_empty @service.list_calendars
        end
      end
    end

    assert_equal(
      [
        { access_token: "google_access_token_alice" },
        {
          client_id: "client_id",
          client_secret: "client_secret",
          token_credential_uri: "https://oauth2.googleapis.com/token",
          refresh_token: "google_refresh_token_alice"
        }
      ],
      constructor_calls
    )
    assert_mock refreshed_client
    assert_mock calendar_api
  end

  test "list_calendars wraps token refresh failures" do
    auth_tokens(:alice_google).update!(expires_at: 1.day.ago)
    original_constructor = Signet::OAuth2::Client.method(:new)
    client_constructor = lambda do |**options|
      raise StandardError, "Network error" unless options.key?(:access_token)

      original_constructor.call(**options)
    end

    Signet::OAuth2::Client.stub(:new, client_constructor) do
      Environ.stub(:[], "credential") do
        error = assert_raises(GoogleCalendarTokenError) { @service.list_calendars }

        assert_equal "Failed to refresh access token: Network error", error.message
      end
    end
  end

  private

  def google_event(id:, summary:, start_time:, stop_time:, description: nil, location: nil)
    Google::Apis::CalendarV3::Event.new(
      id: id,
      summary: summary,
      description: description,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: start_time),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: stop_time),
      status: "confirmed",
      location: location,
      created: start_time - 1.day,
      html_link: "https://calendar.google.com/calendar/event?eid=#{id}"
    )
  end
end
