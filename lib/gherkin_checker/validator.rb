# frozen_string_literal: true

module GherkinChecker
  # Validator class to check tags against rules
  class Validator
    def initialize(config)
      @config = config
    end

    def validate(scenario_data)
      errors = []
      return errors if scenario_data[:error]

      errors << check_one_of_tags(scenario_data)
      errors << check_must_be_tags(scenario_data)
      errors.compact
    end

    private

    def check_one_of_tags(data)
      return nil unless @config.one_of_tags
      return nil if @config.one_of_tags.any? { |tag| data[:tags].include?(tag) }

      format_error(:one_of_tags, @config.one_of_tags, data)
    end

    def check_must_be_tags(data)
      return nil unless @config.must_be_tags
      return nil if @config.must_be_tags.all? { |tag| data[:tags].include?(tag) }

      format_error(:must_be_tags, @config.must_be_tags, data)
    end

    def format_error(type, expected, data)
      {
        check: type,
        file_line: data[:line], # We will need to prepend file path in runner
        scenario_name: data[:name],
        scenario_tags: data[:tags],
        expected: expected
      }
    end
  end
end
