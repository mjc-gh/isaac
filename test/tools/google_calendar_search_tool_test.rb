# frozen_string_literal: true

require "test_helper"

class GoogleCalendarSearchToolTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @tool = GoogleCalendarSearchTool.new(@user)
  end

  test "tool initializes with user and stores it" do
    assert_equal @user, @tool.instance_variable_get(:@user)
  end

  test "tool has correct name" do
    assert_equal "google_calendar_search", @tool.name
  end

  test "tool has description" do
    assert @tool.description.present?
    assert_includes @tool.description.downcase, "calendar"
  end

  test "tool has an optional timezone parameter" do
    assert_includes @tool.parameters.keys, :timezone
    refute @tool.parameters[:timezone].required
  end

  test "execute calls GoogleCalendarService with correct calendar id" do
    start_time = Time.now
    end_time = start_time + 1.hour
    start_iso = start_time.iso8601
    end_iso = end_time.iso8601

    mock_events = [
      { id: "event_1", summary: "Meeting" },
      { id: "event_2", summary: "Standup" }
    ]

    mock_service = Minitest::Mock.new
    mock_service.expect(:list_events, mock_events) do |calendar_id, **kwargs|
      calendar_id == "primary" && kwargs[:start_time].is_a?(Time) && kwargs[:stop_time].is_a?(Time)
    end

    GoogleCalendarService.stub :new, mock_service do
      result = @tool.execute(start_time: start_iso, stop_time: end_iso)

      assert result.present?
      parsed = JSON.parse(result)
      assert_equal 2, parsed.length
      assert_equal "Meeting", parsed[0]["summary"]
    end

    assert_mock(mock_service)
  end

  test "execute uses user's primary_calendar_id when set" do
    start_time = Time.now
    end_time = start_time + 1.hour
    start_iso = start_time.iso8601
    end_iso = end_time.iso8601

    @user.primary_calendar_id = "custom_calendar_id"
    @user.save!

    mock_events = [{ id: "event_1", summary: "Meeting" }]

    mock_service = Minitest::Mock.new
    mock_service.expect(:list_events, mock_events) do |calendar_id, **_kwargs|
      calendar_id == "custom_calendar_id"
    end

    GoogleCalendarService.stub :new, mock_service do
      result = @tool.execute(start_time: start_iso, stop_time: end_iso)

      assert result.present?
      parsed = JSON.parse(result)
      assert_equal 1, parsed.length
    end

    assert_mock(mock_service)
  end

  test "execute uses provided calendar_id parameter" do
    start_time = Time.now
    end_time = start_time + 1.hour
    start_iso = start_time.iso8601
    end_iso = end_time.iso8601
    calendar_id = "provided_calendar_id"

    mock_events = [{ id: "event_1", summary: "Meeting" }]

    mock_service = Minitest::Mock.new
    mock_service.expect(:list_events, mock_events) do |cal_id, **_kwargs|
      cal_id == "provided_calendar_id"
    end

    GoogleCalendarService.stub :new, mock_service do
      result = @tool.execute(start_time: start_iso, stop_time: end_iso, calendar_id:)

      assert result.present?
    end

    assert_mock(mock_service)
  end

  test "execute uses 'primary' as default when no primary_calendar_id" do
    start_time = Time.now
    end_time = start_time + 1.hour
    start_iso = start_time.iso8601
    end_iso = end_time.iso8601

    @user.primary_calendar_id = nil
    @user.save!

    mock_events = []

    mock_service = Minitest::Mock.new
    mock_service.expect(:list_events, mock_events) do |calendar_id, **_kwargs|
      calendar_id == "primary"
    end

    GoogleCalendarService.stub :new, mock_service do
      result = @tool.execute(start_time: start_iso, stop_time: end_iso)

      assert result.present?
    end

    assert_mock(mock_service)
  end

  test "execute handles GoogleCalendarTokenError gracefully" do
    start_time = Time.now
    end_time = start_time + 1.hour
    start_iso = start_time.iso8601
    end_iso = end_time.iso8601

    error_message = "No Google auth token found"

    mock_service = Minitest::Mock.new
    mock_service.expect(:list_events, nil) do |_calendar_id, **_kwargs|
      raise GoogleCalendarTokenError, error_message
    end

    GoogleCalendarService.stub :new, mock_service do
      result = @tool.execute(start_time: start_iso, stop_time: end_iso)

      assert result.present?
      parsed = JSON.parse(result)
      assert parsed["error"]
      assert_includes parsed["error"], "No Google auth token found"
    end
  end

  test "execute parses ISO8601 strings to Time objects" do
    start_time = Time.now
    end_time = start_time + 1.hour
    start_iso = start_time.iso8601
    end_iso = end_time.iso8601

    times_captured = {}

    mock_service = Minitest::Mock.new
    mock_service.expect(:list_events, []) do |_calendar_id, start_time:, stop_time:, search_query:|
      times_captured[:start] = start_time
      times_captured[:stop] = stop_time
      assert_nil search_query
      true
    end

    GoogleCalendarService.stub :new, mock_service do
      result = @tool.execute(start_time: start_iso, stop_time: end_iso)

      assert result.present?
      assert_instance_of Time, times_captured[:start]
      assert_instance_of Time, times_captured[:stop]
    end

    assert_mock(mock_service)
  end

  test "execute uses the user's timezone for timestamps without an offset" do
    @user.update!(timezone: "Eastern Time (US & Canada)")
    captured_times = []
    mock_service = Minitest::Mock.new
    mock_service.expect(:list_events, []) do |_calendar_id, start_time:, stop_time:, **_kwargs|
      captured_times.push(start_time, stop_time)
      true
    end

    GoogleCalendarService.stub :new, mock_service do
      @tool.execute(start_time: "2026-07-27T09:00:00", stop_time: "2026-07-27T10:00:00")
    end

    assert_equal "2026-07-27T09:00:00-04:00", captured_times[0].iso8601
    assert_equal "2026-07-27T10:00:00-04:00", captured_times[1].iso8601
    assert_mock(mock_service)
  end

  test "execute uses the optional timezone parameter" do
    @user.update!(timezone: "Eastern Time (US & Canada)")
    captured_time = nil
    mock_service = Minitest::Mock.new
    mock_service.expect(:list_events, []) do |_calendar_id, start_time:, **_kwargs|
      captured_time = start_time
      true
    end

    GoogleCalendarService.stub :new, mock_service do
      @tool.execute(
        start_time: "2026-07-27T09:00:00",
        stop_time: "2026-07-27T10:00:00",
        timezone: "Pacific Time (US & Canada)"
      )
    end

    assert_equal "2026-07-27T09:00:00-07:00", captured_time.iso8601
    assert_mock(mock_service)
  end

  test "execute returns events as JSON string" do
    start_time = Time.now
    end_time = start_time + 1.hour
    start_iso = start_time.iso8601
    end_iso = end_time.iso8601

    mock_events = [
      { id: "event_1", summary: "Meeting", start: start_time, stop: end_time }
    ]

    mock_service = Minitest::Mock.new
    mock_service.expect(:list_events, mock_events) do |_calendar_id, **_kwargs|
      true
    end

    GoogleCalendarService.stub :new, mock_service do
      result = @tool.execute(start_time: start_iso, stop_time: end_iso)

      assert_instance_of String, result
      parsed = JSON.parse(result)
      assert parsed.is_a?(Array)
      assert_equal 1, parsed.length
    end

    assert_mock(mock_service)
  end
end
