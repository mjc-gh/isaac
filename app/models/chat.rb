# frozen_string_literal: true

# simplecov:disable
class Chat < ApplicationRecord
  acts_as_chat

  belongs_to :user
end
# simplecov:disable
