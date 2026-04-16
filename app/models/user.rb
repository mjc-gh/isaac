# frozen_string_literal: true

class User < ApplicationRecord
  normalizes :email, with: ->(email) { email.downcase }

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :first_name, length: { minimum: 2, maximum: 50 }, allow_blank: true
  validates :last_name, length: { minimum: 2, maximum: 50 }, allow_blank: true
end
