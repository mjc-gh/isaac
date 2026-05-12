# frozen_string_literal: true

module Users
  class AuthTokensController < ApplicationController
    before_action :require_authentication
    before_action :set_auth_token, only: [:destroy]

    def index
      @auth_tokens = current_user.auth_tokens
    end

    def destroy
      @auth_token.destroy
      redirect_to users_auth_tokens_url, notice: I18n.t("auth_tokens.disconnected"), status: :see_other
    end

    private

    def set_auth_token
      @auth_token = current_user.auth_tokens.find(params[:id])
    end
  end
end
