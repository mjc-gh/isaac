# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def login(user:, token:)
    @user = user
    @token = token

    mail(to: @user.email, subject: I18n.t("user_mailer.login.subject"))
  end
end
