# frozen_string_literal: true

class AuthToken < ApplicationRecord
  belongs_to :user

  encrypts :access_token, :refresh_token

  validates :provider, presence: true, uniqueness: { scope: :user_id }
  validates :access_token, presence: true
end
