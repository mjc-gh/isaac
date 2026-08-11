# frozen_string_literal: true

class RelativeDateTimeTool < RubyLLM::Tool
  desc "Get a relative time, like '5 minutes ago' or 'next Thursday at 3pm', as ISO8601 format"

  param :relative_time, type: "string", desc: "Relative time to be converted to absolute time"

  def initialize(user)
    @user = user
  end

  def execute(relative_time:)
    time = @user.with_timezone do
      Chronic.parse_in_zone(relative_time)
    end

    return { error: "Invalid relative_time" } if time.nil?

    time.iso8601
  end
end
