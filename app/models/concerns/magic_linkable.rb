# frozen_string_literal: true

module MagicLinkable
  extend ActiveSupport::Concern

  class_methods do
    def find_by_magic_link_token(token, for:)
      GlobalID::Locator.locate_signed(token, for:)
    end
  end

  def generate_magic_link_token(expires_in: 24.hours, for:)
    to_signed_global_id(expires_in:, for:).to_s
  end
end
