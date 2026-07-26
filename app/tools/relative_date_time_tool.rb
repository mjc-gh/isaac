class RelativeDateTimeTool < RubyLLM::Tool
  desc "Get a relative time, like '5 minutes ago' or '12 hours ago', as ISO8601 format"

  param :relative_time, type: "string", desc: "Relative time to be converted to absolute time"

  def execute(relative_time:)
    time = Chronic.parse(relative_time)

    return { error: "Invalid relative_time" } if time.nil?

    time.iso8601
  end
end
