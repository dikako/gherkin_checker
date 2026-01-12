# frozen_string_literal: true

require "yaml"

module GherkinChecker
  # Config class to handle configuration loading
  class Config
    attr_reader :feature_files_path, :one_of_tags, :must_be_tags

    def initialize(config_file = "gherkin_checker.yml")
      @config = load_config(config_file)
      @feature_files_path = @config.fetch("feature_files_path", "./features")
      @one_of_tags = @config.dig("mandatory_tags", "one_of")
      @must_be_tags = @config.dig("mandatory_tags", "must_be")
    end

    private

    def load_config(file)
      return {} unless File.exist?(file)

      YAML.load_file(file) || {}
    end
  end
end
