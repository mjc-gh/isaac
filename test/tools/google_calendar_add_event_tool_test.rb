# frozen_string_literal: true

require "test_helper"

class GoogleCalendarAddEventToolTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @tool = GoogleCalendarAddEventTool.new(@user)
    @arguments = {
      title: "Planning",
      start_time: "2026-07-27T09:00:00-04:00",
      stop_time: "2026-07-27T10:00:00-04:00",
      description: "Discuss the upcoming release"
    }
  end

  test "tool has the expected name, description, and parameters" do
    assert_equal "google_calendar_add_event", @tool.name
    assert_includes @tool.description.downcase, "calendar"
    assert_equal %i[title start_time stop_time description calendar_id timezone], @tool.parameters.keys
    assert @tool.parameters.values_at(:title, :start_time, :stop_time, :description).all?(&:required)
    refute @tool.parameters[:calendar_id].required
    refute @tool.parameters[:timezone].required
    assert_includes @tool.parameters[:start_time].description, "timezone"
    assert_includes @tool.parameters[:stop_time].description, "timezone"
  end

  test "tool initializes with and retains the user" do
    assert_equal @user, @tool.instance_variable_get(:@user)
  end

  test "execute parses times, delegates to the service, and returns JSON" do
    expected_event = { id: "event_1", summary: "Planning", status: "confirmed" }
    mock_service = Minitest::Mock.new
    mock_service.expect(:add_event, expected_event) do |calendar_id, title:, start_time:, stop_time:, description:|
      calendar_id == "primary" && title == "Planning" && description == "Discuss the upcoming release" &&
        start_time == Time.parse(@arguments[:start_time]) && stop_time == Time.parse(@arguments[:stop_time])
    end

    GoogleCalendarService.stub :new, mock_service do
      assert_equal expected_event.stringify_keys, JSON.parse(@tool.execute(**@arguments))
    end

    assert_mock mock_service
  end

  test "execute uses the user's primary calendar" do
    @user.primary_calendar_id = "custom_calendar"
    @user.save!
    mock_service = Minitest::Mock.new
    mock_service.expect(:add_event, {}) { |calendar_id, **_kwargs| calendar_id == "custom_calendar" }

    GoogleCalendarService.stub :new, mock_service do
      @tool.execute(**@arguments)
    end

    assert_mock mock_service
  end

  test "execute uses the provided calendar id" do
    mock_service = Minitest::Mock.new
    mock_service.expect(:add_event, {}) { |calendar_id, **_kwargs| calendar_id == "provided_calendar" }

    GoogleCalendarService.stub :new, mock_service do
      @tool.execute(**@arguments, calendar_id: "provided_calendar")
    end

    assert_mock mock_service
  end

  test "execute uses the user's timezone for timestamps without an offset" do
    @user.update!(timezone: "Eastern Time (US & Canada)")
    captured_times = []
    mock_service = Minitest::Mock.new
    mock_service.expect(:add_event, {}) do |_calendar_id, start_time:, stop_time:, **_kwargs|
      captured_times.push(start_time, stop_time)
      true
    end

    GoogleCalendarService.stub :new, mock_service do
      @tool.execute(
        title: "Planning",
        start_time: "2026-07-27T09:00:00",
        stop_time: "2026-07-27T10:00:00",
        description: "Discuss the upcoming release"
      )
    end

    assert_equal "2026-07-27T09:00:00-04:00", captured_times[0].iso8601
    assert_equal "2026-07-27T10:00:00-04:00", captured_times[1].iso8601
    assert_mock mock_service
  end

  test "execute uses the optional timezone parameter" do
    captured_time = nil
    mock_service = Minitest::Mock.new
    mock_service.expect(:add_event, {}) do |_calendar_id, start_time:, **_kwargs|
      captured_time = start_time
      true
    end

    GoogleCalendarService.stub :new, mock_service do
      @tool.execute(
        **@arguments.merge(start_time: "2026-07-27T09:00:00", stop_time: "2026-07-27T10:00:00"),
        timezone: "Pacific Time (US & Canada)"
      )
    end

    assert_equal "2026-07-27T09:00:00-07:00", captured_time.iso8601
    assert_mock mock_service
  end

  test "execute falls back to the primary Google calendar" do
    @user.primary_calendar_id = nil
    @user.save!
    mock_service = Minitest::Mock.new
    mock_service.expect(:add_event, {}) { |calendar_id, **_kwargs| calendar_id == "primary" }

    GoogleCalendarService.stub :new, mock_service do
      @tool.execute(**@arguments)
    end

    assert_mock mock_service
  end

  test "execute returns Google credential errors as JSON" do
    mock_service = Minitest::Mock.new
    mock_service.expect(:add_event, nil) { raise GoogleCalendarTokenError, "No Google auth token found" }

    GoogleCalendarService.stub :new, mock_service do
      result = JSON.parse(@tool.execute(**@arguments))
      assert_equal "No Google auth token found", result["error"]
    end
  end
end
