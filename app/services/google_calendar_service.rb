# frozen_string_literal: true

class GoogleCalendarService
  def initialize(user)
    @user = user
  end

  def list_calendars
    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = auth_client

    response = service.list_calendar_lists
    response.items.map { self.class.calendar_hash(it) }
  end

  def list_events(calendar_id, start_time:, stop_time:, search_query: nil)
    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = auth_client

    kwargs = { time_min: start_time.iso8601, time_max: stop_time.iso8601 }
    kwargs[:q] = search_query if search_query.present?

    response = service.list_events(calendar_id, **kwargs)
    items = response.items.map { self.class.event_hash(it) }
    items.sort_by! { it[:start] }
    items.reverse!
    items
  end

  def add_event(calendar_id, title:, start_time:, stop_time:, description:)
    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = auth_client

    event = Google::Apis::CalendarV3::Event.new(
      summary: title,
      description:,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: start_time),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: stop_time)
    )

    self.class.event_hash(service.insert_event(calendar_id, event))
  end

  def self.calendar_hash(calendar)
    {
      id: calendar.id,
      summary: calendar.summary,
      primary: calendar.primary
    }
  end

  def self.event_hash(event)
    {
      id: event.id,
      summary: event.summary,
      description: event.description,
      start: event.start&.date_time,
      stop: event.end&.date_time,
      status: event.status,
      location: event.location,
      created: event.created,
      link: event.html_link
    }
  end

  private

  def auth_client
    @auth_client ||= begin
      auth_token = find_google_auth_token
      raise GoogleCalendarTokenError, "No Google auth token found" unless auth_token

      get_valid_oauth_client(auth_token)
    end
  end

  def find_google_auth_token
    @user.auth_tokens.find_by(provider: "google_oauth2")
  end

  def get_valid_oauth_client(auth_token)
    # Create a client with the current access token
    token = Signet::OAuth2::Client.new(access_token: auth_token.access_token)

    # Check if token is expired
    if auth_token.expired?
      # Try to refresh the token if refresh_token is available
      raise GoogleCalendarTokenError, "Access token expired and no refresh token available" if auth_token.refresh_token.blank?

      return refresh_and_get_client(auth_token)
    end

    token
  end

  def refresh_and_get_client(auth_token)
    token = Signet::OAuth2::Client.new(
      client_id: Environ["ISAAC_GOOGLE_CLIENT_ID"],
      client_secret: Environ["ISAAC_GOOGLE_CLIENT_SECRET"],
      token_credential_uri: "https://oauth2.googleapis.com/token",
      refresh_token: auth_token.refresh_token
    )

    token.refresh!
    token
  rescue StandardError => e
    raise GoogleCalendarTokenError, "Failed to refresh access token: #{e.message}"
  end
end
