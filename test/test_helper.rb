# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

if ENV["COVERAGE"].present?
  require "simplecov"
  require "simplecov-console"

  SimpleCov.start(:rails) do
    minimum_coverage 100
    enable_coverage :branch

    add_filter "vendor"
    add_filter "test"

    # NOTE: This is loaded as part of app environment and we cannot
    # correctly measure code coverage as a result.
    add_filter "lib/environ.rb"
  end

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console
  ])

  SimpleCov::Formatter::Console.use_colors = $stdout.tty?
  SimpleCov::Formatter::Console.show_covered = ENV["COVERAGE_FULL"]
  SimpleCov::Formatter::Console.output_style = "table"
end

module ActiveSupport
  class TestCase
    include ActionMailer::TestHelper

    # SimpleCov set up for parallel tests
    parallelize_setup do |_worker|
      SimpleCov.command_name "Job::#{Process.pid}" if const_defined?(:SimpleCov)
    end

    parallelize_teardown do |_worker|
      SimpleCov.result if const_defined?(:SimpleCov)
    end

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
  end
end
