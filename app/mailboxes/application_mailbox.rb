# frozen_string_literal: true

class ApplicationMailbox < ActionMailbox::Base
  routing ->(mail) { mail.to.include?(Environ["ISAAC_SENDER_ADDRESS"]) } => :assistant
end
