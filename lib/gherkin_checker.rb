# frozen_string_literal: true

require "find"
require "yaml"
require "gherkin/parser"

require_relative "gherkin_checker/version"

module GherkinChecker
  # Checker class
  class Checker
    def initialize(config_file = "gherkin_checker.yml")
      unless File.exist?(config_file)
        log_message("Error: Configuration file #{config_file} not found.", level: :error)
        exit(1) # Exit with a status of 1 to indicate an error
      end

      @config = YAML.load_file(config_file)
      if @config
        @skip_check = false
      else
        log_message("Warning: The gherkin_checker.yml not define", level: :warn)
        @skip_check = true
      end

      @feature_files_path = @config&.key?("feature_files_path") ? @config.fetch("feature_files_path") : "./features"
      @one_of_tags = @config.dig("mandatory_tags", "one_of") if @config
      @must_be_tags = @config.dig("mandatory_tags", "must_be") if @config

      # Flags to ensure warnings are only printed once
      @one_of_tags_warning_shown = false
      @must_be_tags_warning_shown = false
    end

    def check_feature_files
      errors = []
      Find.find(@feature_files_path) do |file|
        next unless File.extname(file) == ".feature"

        errors += check_one_of_tags(file)
        errors += check_must_be_tags(file)
      end

      report_errors(errors)
    end

    private

    def check_one_of_tags(file)
      return log_one_of_tags_warning if @one_of_tags.nil?

      errors = []
      extract_scenario_data(file).each do |data|
        is_tags_nil = data[:scenario_tags].nil?
        tags = data[:scenario_tags]
        file_line = data[:file_line]
        scenario = data[:scenario_name]
        error = data[:error]

        if is_tags_nil
          errors << {
            check: :one_of_tags,
            file_line: file_line,
            scenario_name: scenario,
            scenario_tags: tags,
            error: error
          }
        end

        next if is_tags_nil

        next if @one_of_tags.any? { |tag| tags.include?(tag) }

        errors << {
          check: :one_of_tags,
          file_line: file_line,
          scenario_name: scenario,
          scenario_tags: tags,
          error: error
        }
      end

      errors
    end

    def check_must_be_tags(file)
      return log_must_be_tags_warning if @must_be_tags.nil?

      errors = []
      extract_scenario_data(file).each do |data|
        is_tags_nil = data[:scenario_tags].nil?
        tags = data[:scenario_tags]
        file_line = data[:file_line]
        scenario = data[:scenario_name]
        error = data[:error]

        if is_tags_nil
          errors << {
            check: :must_be_tags,
            file_line: file_line,
            scenario_name: scenario,
            scenario_tags: tags,
            error: error
          }
        end

        next if is_tags_nil

        next if @must_be_tags.all? { |item| tags.include?(item) }

        errors << {
          check: :must_be_tags,
          file_line: file_line,
          scenario_name: scenario,
          scenario_tags: tags,
          error: error
        }
      end

      errors
    end

    def log_one_of_tags_warning
      return [] if @one_of_tags_warning_shown

      log_message("Warning: Optional tags not set in 'gherkin_checker.yml'.", level: :warn) unless @skip_check
      @one_of_tags_warning_shown = true
      [] # Return an empty array to maintain consistency
    end

    def log_must_be_tags_warning
      return [] if @must_be_tags_warning_shown

      log_message("Warning: Mandatory tags not set in 'gherkin_checker.yml'.", level: :warn) unless @skip_check
      @must_be_tags_warning_shown = true
      [] # Return an empty array to maintain consistency
    end

    def report_errors(errors)
      if errors.empty?
        if @skip_check
          log_message("Skip gherkin checking", level: :warn)
        else
          log_message("All scenarios have the required tags.")
        end
      else
        log_message("Gherkin Checker found Error:", level: :error)
        errors.each do |error|
          error_message = error[:error]
          if error_message.nil?
            scenario_tags = error[:scenario_tags]
            tags = scenario_tags
            tags = scenario_tags.nil? ? "Tagging not set" : "Just found '#{tags}'"

            message = case error[:check]
                      when :one_of_tags
                        "one_of_tags '#{@one_of_tags}' not found!, #{tags}"
                      when :must_be_tags
                        "must_be_tags '#{@must_be_tags}' not found!, #{tags}"
                      else
                        "error undefined"
                      end

            log_message("#{error[:file_line]}: #{error[:scenario_name]} - #{message}", level: :error)
          else
            log_message("Error: #{error_message}", level: :error)
          end
        end
      end
    end

    # Define a method to log messages with different levels
    def log_message(message, level: :info)
      # Define color codes
      colors = {
        debug: "\e[36m", # Cyan
        info: "\e[32m", # Green
        warn: "\e[33m", # Yellow
        error: "\e[31m", # Red
        fatal: "\e[35m", # Magenta
        reset: "\e[0m" # Reset to default color
      }

      color = colors[level] || colors[:reset]

      puts "#{color}#{message}#{colors[:reset]}"
    end

    def extract_scenario_data(file)
      gherkin_parser = Gherkin::Parser.new
      scenario_data = []

      begin
        content = File.read(file)
        document = gherkin_parser.parse(content)
        feature = document.feature
        feature_name = feature.name
        feature_tags = feature.tags.map(&:name)

        feature.children.each do |child|
          raise "Error: read scenario data" unless child.respond_to?(:scenario) && child.scenario

          scenario = child.scenario
          scenario_name = scenario.name
          scenario_tags = scenario.tags.map(&:name)
          scenario_tags = scenario_tags.map { |tag| tag.delete_prefix("@") }
          location_line = scenario.location.line
          location_column = scenario.location.column

          scenario_data << {
            feature_name: feature_name,
            feature_tags: feature_tags,
            file_line: "#{file}:#{location_line}:#{location_column}",
            scenario_name: scenario_name,
            scenario_tags: scenario_tags,
            error: nil
          }
        end
      rescue StandardError => e
        scenario_data << {
          feature_name: nil,
          feature_tags: nil,
          file_line: nil,
          scenario_name: nil,
          scenario_tags: nil,
          error: e.message
        }
      end

      scenario_data
    end
  end
end
