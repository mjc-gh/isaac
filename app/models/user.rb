# frozen_string_literal: true

class User < ApplicationRecord
  has_many :user_aliases, dependent: :destroy

  normalizes :email, with: ->(email) { email.downcase }

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :email_not_alias_email

  validates :first_name, length: { minimum: 2, maximum: 50 }, allow_blank: true
  validates :last_name, length: { minimum: 2, maximum: 50 }, allow_blank: true

  private

  def email_not_alias_email
    return if email.blank?

    return unless UserAlias.exists?(email: email)
    errors.add(:email, "is already used as an alias email")
  end
end
