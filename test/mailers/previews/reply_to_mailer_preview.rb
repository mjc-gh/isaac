# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/reply_to_mailer
class ReplyToMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/reply_to_mailer/threaded_email
  delegate :threaded_email, to: :ReplyToMailer
end
