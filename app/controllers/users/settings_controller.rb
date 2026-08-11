# frozen_string_literal: true

module Users
  class SettingsController < ApplicationController
    before_action :require_authentication

    def edit
      @timezones = ActiveSupport::TimeZone.all
    end

    def update
      current_user.assign_attributes(settings_params)

      if current_user.save
        redirect_to edit_users_settings_url, notice: I18n.t("settings.updated"), status: :see_other
      else
        @timezones = ActiveSupport::TimeZone.all
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def settings_params
      params.require(:user).permit(:timezone)
    end
  end
end
