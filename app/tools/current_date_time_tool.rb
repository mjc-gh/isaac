# frozen_string_literal: true

class CurrentDateTimeTool < RubyLLM::Tool
  desc "Get the current date time in ISO8601 format"

  def execute = Time.current.iso8601
end
