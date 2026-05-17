# frozen_string_literal: true

class GoogleCalendarSearchTool < RubyLLM::Tool
  description "Search for events in a user's Google Calendar within a specified time range"

  param :start_time, type: "string", desc: "Start of the time range in ISO8601 format (e.g., '2025-05-17T09:00:00Z')", required: true
  param :stop_time, type: "string", desc: "End of the time range in ISO8601 format (e.g., '2025-05-17T17:00:00Z')", required: true
  param :calendar_id, type: "string", desc: "Calendar ID to search (defaults to user's primary calendar)", required: false

  def initialize(user)
    @user = user
  end

  def execute(start_time:, stop_time:, calendar_id: nil)
    # Parse ISO8601 strings to Time objects (service expects Time objects)
    start_time_obj = Time.parse(start_time)
    stop_time_obj = Time.parse(stop_time)

    # Use provided calendar_id, fall back to user's primary_calendar_id, then to "primary"
    calendar_to_search = calendar_id || @user.primary_calendar_id || "primary"

    # Call the service to list events
    events = GoogleCalendarService.new(@user).list_events(
      calendar_to_search,
      start_time: start_time_obj,
      stop_time: stop_time_obj
    )

    # Return events as JSON string for the LLM to process
    events.to_json
  rescue GoogleCalendarTokenError => e
    { error: e.message }.to_json
  end
end
