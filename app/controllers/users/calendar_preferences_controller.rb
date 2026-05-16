# frozen_string_literal: true

module Users
  class CalendarPreferencesController < ApplicationController
    before_action :require_authentication
    before_action :check_google_token

    def edit
      @calendars = fetch_calendars
      @selected_calendar_id = current_user.primary_calendar_id
    end

    def update
      current_user.primary_calendar_id = params[:calendar_id]
      current_user.save!
      redirect_to users_auth_tokens_url, notice: I18n.t("calendar_preferences.updated"), status: :see_other
    end

    private

    def check_google_token
      return if current_user.auth_tokens.exists?(provider: "google_oauth2")

      redirect_to users_auth_tokens_url, alert: I18n.t("calendar_preferences.no_google_token")
    end

    def fetch_calendars
      service = GoogleCalendarService.new(current_user)
      service.list_calendars
    rescue StandardError => e
      Rails.logger.error("Error fetching calendars: #{e.message}")
      []
    end
  end
end
