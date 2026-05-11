# frozen_string_literal: true

require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:alice)
  end

  test "login sends email to user" do
    token = @user.generate_magic_link_token(for: :session)
    mail = UserMailer.login(user: @user, token:)

    assert_equal [@user.email], mail.to
  end

  test "login sets correct subject" do
    token = @user.generate_magic_link_token(for: :session)
    mail = UserMailer.login(user: @user, token:)

    assert_equal I18n.t("user_mailer.login.subject"), mail.subject
  end

  test "login email contains magic link" do
    token = @user.generate_magic_link_token(for: :session)
    mail = UserMailer.login(user: @user, token:)

    assert_match token, mail.body.encoded
  end
end
