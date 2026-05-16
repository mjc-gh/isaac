# frozen_string_literal: true

module Users
  class OauthCallbacksController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:create]
    before_action :require_authentication

    def create
      auth_hash = request.env["omniauth.auth"]
      provider = auth_hash["provider"]

      auth_token = current_user.auth_tokens.find_or_initialize_by(provider:)
      auth_token.access_token = auth_hash.dig("credentials", "token")
      auth_token.refresh_token = auth_hash.dig("credentials", "refresh_token")
      auth_token.scopes = ["https://www.googleapis.com/auth/calendar"]

      # Set expires_at if provided in credentials, otherwise set a default far future date
      expires_at_value = auth_hash.dig("credentials", "expires_at")
      auth_token.expires_at = expires_at_value ? Time.at(expires_at_value) : 1.year.from_now

      if auth_token.save
        redirect_to users_auth_tokens_url, notice: I18n.t("auth_tokens.connected")
      else
        redirect_to users_auth_tokens_url, alert: I18n.t("auth_tokens.failure")
      end
    end

    def failure
      redirect_to users_auth_tokens_url, alert: I18n.t("auth_tokens.failure", reason: params[:message])
    end
  end
end
