# frozen_string_literal: true

class CurrentDateTimeTool < RubyLLM::Tool
  desc "Get the current date time in ISO8601 format"

  def initialize(user)
    @user = user
  end

  def execute = @user.with_timezone { Time.current.iso8601 }
end
