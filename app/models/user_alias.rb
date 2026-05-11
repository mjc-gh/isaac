# frozen_string_literal: true

class UserAlias < ApplicationRecord
  belongs_to :user

  normalizes :email, with: ->(email) { email.downcase }

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :email_not_user_email

  private

  def email_not_user_email
    return if email.blank?

    return unless User.exists?(email: email)
    errors.add(:email, "is already used as a primary user email")
  end
end
