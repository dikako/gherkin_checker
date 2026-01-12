# frozen_string_literal: true

require "find"
require_relative "gherkin_checker/version"
require_relative "gherkin_checker/config"
require_relative "gherkin_checker/parser"
require_relative "gherkin_checker/validator"

module GherkinChecker
  # Checker class - The main runner
  class Checker
    def initialize(config_file = "gherkin_checker.yml")
      @config = Config.new(config_file)
      @parser = Parser.new
      @validator = Validator.new(@config)
    end

    def check_feature_files
      return log_skip_message if skip_check?

      errors = []
      Find.find(@config.feature_files_path) do |file|
        next unless File.extname(file) == ".feature"

        scenarios = @parser.parse(file)
        scenarios.each do |scenario|
          if scenario[:error]
            errors << scenario
          else
            validation_errors = @validator.validate(scenario)
            # Prepend file path to the error
            validation_errors.each { |err| err[:file_line] = "#{file}:#{err[:file_line]}:#{scenario[:column]}" }
            errors += validation_errors
          end
        end
      end

      report_errors(errors)
    end

    private

    def skip_check?
      # If no config was loaded (meaning no file found or empty), we might want to warn
      # But based on original logic, if config is missing, we warn and skip.
      # Config class handles loading. If attributes are nil, it means load failed or empty.
      # Let's check if critical config is present.
      @config.one_of_tags.nil? && @config.must_be_tags.nil?
    end

    def log_skip_message
      log_message("Warning: The gherkin_checker.yml not define or no tags configured", level: :warn)
      log_message("Skip gherkin checking", level: :warn)
    end

    def report_errors(errors)
      if errors.empty?
        log_message("All scenarios have the required tags.")
      else
        log_message("Gherkin Checker found Error:", level: :error)
        errors.each do |error|
          if error[:error]
            log_syntax_error(error)
          else
            log_validation_error(error)
          end
        end
      end
    end

    def log_syntax_error(error)
      type = error[:type] == :syntax_error ? "Syntax Error" : "Error"
      log_message("#{type}: #{error[:error]}", level: :error)
    end

    def log_validation_error(error)
      tags_str = if error[:scenario_tags].nil? || error[:scenario_tags].empty?
                   "Tagging not set"
                 else
                   "Just found '#{error[:scenario_tags]}'"
                 end
      check_type = error[:check] == :one_of_tags ? "one_of_tags" : "must_be_tags"

      message = "#{check_type} '#{error[:expected]}' not found!, #{tags_str}"
      log_message("#{error[:file_line]}: #{error[:scenario_name]} - #{message}", level: :error)
    end

    def log_message(message, level: :info)
      colors = {
        debug: "\e[36m",
        info: "\e[32m",
        warn: "\e[33m",
        error: "\e[31m",
        fatal: "\e[35m",
        reset: "\e[0m"
      }
      color = colors[level] || colors[:reset]
      puts "#{color}#{message}#{colors[:reset]}"
    end
  end
end
