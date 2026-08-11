# frozen_string_literal: true

class GoogleCalendarSearchTool < RubyLLM::Tool
  description "Search for events on the user's calendar between a given time range."

  param :start_time, type: "string", desc: "Start of the time range as a timezone-naive ISO8601 timestamp; the user's configured timezone is used", required: true
  param :stop_time, type: "string", desc: "End of the time range as a timezone-naive ISO8601 timestamp; the user's configured timezone is used", required: true
  param :search_query, type: "string", desc: "Free-text search term to filter events", required: false
  param :calendar_id, type: "string", desc: "Calendar ID to search (defaults to user's primary calendar)", required: false
  param :timezone, type: "string", desc: "Only set this when the user explicitly specifies a timezone different from their configured timezone", required: false

  def initialize(user)
    @user = user
  end

  def execute(start_time:, stop_time:, search_query: nil, calendar_id: nil, timezone: nil)
    # Local timestamps use the user's timezone; an explicit timezone is an exception.
    time_zone = ActiveSupport::TimeZone[timezone.presence || @user.timezone]
    start_time_obj = time_zone.parse(start_time).to_time
    stop_time_obj = time_zone.parse(stop_time).to_time

    # Use provided calendar_id, fall back to user's primary_calendar_id, then to "primary"
    calendar_to_search = calendar_id || @user.primary_calendar_id || "primary"

    # Call the service to list events
    events = GoogleCalendarService.new(@user).list_events(
      calendar_to_search,
      start_time: start_time_obj,
      stop_time: stop_time_obj,
      search_query:
    )

    # Return events as JSON string for the LLM to process
    events.to_json
  rescue GoogleCalendarTokenError => e
    { error: e.message }.to_json
  end
end
