# frozen_string_literal: true

require "find"
require "yaml"
require "set"

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
      extract_scenarios_with_tags(file).each do |data|
        is_tags_nil = data[:tags].nil?
        tags = data[:tags]
        file_line = data[:file_line]
        scenario = data[:scenario]

        if is_tags_nil
          errors << {
            check: :one_of_tags,
            file_line: file_line,
            scenario: scenario,
            tags: tags
          }
        end

        next if is_tags_nil

        next if @one_of_tags.any? { |tag| tags.include?(tag) }

        errors << {
          check: :one_of_tags,
          file_line: file_line,
          scenario: scenario,
          tags: tags
        }
      end

      errors
    end

    def check_must_be_tags(file)
      return log_must_be_tags_warning if @must_be_tags.nil?

      errors = []
      extract_scenarios_with_tags(file).each do |data|
        is_tags_nil = data[:tags].nil?
        tags = data[:tags]
        file_line = data[:file_line]
        scenario = data[:scenario]

        if is_tags_nil
          errors << {
            check: :must_be_tags,
            file_line: file_line,
            scenario: scenario,
            tags: tags
          }
        end

        next if is_tags_nil

        next if @must_be_tags.all? { |item| tags.include?(item) }

        errors << {
          check: :must_be_tags,
          file_line: file_line,
          scenario: scenario,
          tags: tags
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
          tags = error[:tags]
          tags = error[:tags].nil? ? "Tagging not set" : "Just found '#{tags}'"

          message = case error[:check]
                    when :one_of_tags
                      "one_of_tags '#{@one_of_tags}' not found!, #{tags}"
                    when :must_be_tags
                      "must_be_tags '#{@must_be_tags}' not found!, #{tags}"
                    else
                      "error undefined"
                    end

          # Log error to console
          log_message("#{error[:file_line]}: #{error[:scenario]} - #{message}", level: :error)
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

    def extract_scenarios_with_tags(file)
      scenarios = []
      current_tags = []

      lines = File.readlines(file)

      lines.each_with_index do |line, index|
        # Remove leading/trailing whitespace
        line.strip!

        if line.start_with?("@")
          # Capture tags if line contains tags
          current_tags = line.scan(/@(\w+)/).flatten
        elsif line.start_with?("Scenario:", "Scenario Outline:")
          # Capture scenario names
          scenario_name = line.sub(/^Scenario(?: Outline)?:\s*/, "").strip
          # Store scenario with current tags (nil if no tags), then reset tags for next scenario
          scenarios << {
            file_line: "#{file}:#{index + 1}",
            scenario: scenario_name,
            tags: current_tags.empty? ? nil : current_tags.dup
          }
          current_tags = [] # Reset tags for next scenario
        end
      end

      scenarios
    end
  end
end
