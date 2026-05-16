# frozen_string_literal: true

class GoogleCalendarService
  def initialize(user)
    @user = user
  end

  def list_calendars
    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = auth_client
    response = service.list_calendar_lists
    response.items.map { |calendar| calendar_hash(calendar) }
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
    if token_expired?(token)
      # Try to refresh the token if refresh_token is available
      raise GoogleCalendarTokenError, "Access token expired and no refresh token available" if auth_token.refresh_token.blank?
      return refresh_and_get_client(auth_token)
    end

    token
  end

  def token_expired?(token)
    # Signet::OAuth2::Client stores expiration in the @expires_at attribute
    # If expires_at is nil, the token doesn't expire or we don't have expiration info
    return false if token.expires_at.nil?

    Time.now >= token.expires_at
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

  def calendar_hash(calendar)
    {
      id: calendar.id,
      summary: calendar.summary,
      primary: calendar.primary
    }
  end
end
