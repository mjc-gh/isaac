# frozen_string_literal: true

module Users
  class SessionsController < ApplicationController
    include UserVerifiable

    def new
    end

    def create
      @user = User.find_by(email: params[:email])

      if @user
        token = @user.generate_magic_link_token(for: :session)
        UserMailer.login(user: @user, token:).deliver_later
      end

      redirect_to new_users_session_path, notice: I18n.t("sessions.magic_link_sent")
    end

    def destroy
      sign_out
      redirect_to root_path, notice: I18n.t("sessions.signed_out")
    end

    private

    def redirect_on_verification_failed
      redirect_to new_users_session_path, alert: I18n.t("sessions.invalid_token")
    end

    def handle_verification_success
      sign_in(@user)
      redirect_to root_path, notice: I18n.t("sessions.signed_in")
    end
  end
end
