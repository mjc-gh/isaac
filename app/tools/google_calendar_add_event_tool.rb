# frozen_string_literal: true

class GoogleCalendarAddEventTool < RubyLLM::Tool
  description "Add an event to the user's calendar."

  param :title, type: "string", desc: "Title of the event", required: true
  param :start_time, type: "string", desc: "Event start time as a timezone-naive ISO8601 timestamp; the user's configured timezone is used", required: true
  param :stop_time, type: "string", desc: "Event stop time as a timezone-naive ISO8601 timestamp; the user's configured timezone is used", required: true
  param :description, type: "string", desc: "Description of the event", required: true
  param :calendar_id, type: "string", desc: "Calendar ID to add the event to (defaults to user's primary calendar)", required: false
  param :timezone, type: "string", desc: "Only set this when the user explicitly specifies a timezone different from their configured timezone", required: false

  def initialize(user)
    @user = user
  end

  def execute(title:, start_time:, stop_time:, description:, calendar_id: nil, timezone: nil)
    # Local timestamps use the user's timezone; an explicit timezone is an exception.
    time_zone = ActiveSupport::TimeZone[timezone.presence || @user.timezone]
    start_time_obj = time_zone.parse(start_time).to_time
    stop_time_obj = time_zone.parse(stop_time).to_time
    calendar_to_add = calendar_id || @user.primary_calendar_id || "primary"

    event = GoogleCalendarService.new(@user).add_event(
      calendar_to_add,
      title:,
      start_time: start_time_obj,
      stop_time: stop_time_obj,
      description:
    )

    event.to_json
  rescue GoogleCalendarTokenError => e
    { error: e.message }.to_json
  end
end
