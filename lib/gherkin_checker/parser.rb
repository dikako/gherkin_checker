# frozen_string_literal: true

require "gherkin/parser"
require "gherkin/errors"

module GherkinChecker
  # Parser class to handle Gherkin file parsing
  class Parser
    def initialize
      @parser = Gherkin::Parser.new
    end

    def parse(file_path)
      content = File.read(file_path)
      document = @parser.parse(content)
      feature = document.feature

      return [] unless feature

      feature_name = feature.name
      feature_tags = feature.tags.map(&:name).map { |tag| tag.delete_prefix("@") }

      feature.children.map do |child|
        process_child(child, feature_name, feature_tags)
      end.compact
    rescue Gherkin::CompositeParserException => e
      e.errors.map do |error|
        { error: error.message, type: :syntax_error }
      end
    rescue Gherkin::ParserError => e
      [{ error: e.message, type: :syntax_error }]
    rescue StandardError => e
      [{ error: e.message, type: :unknown_error }]
    end

    private

    def process_child(child, feature_name, feature_tags)
      return unless child.respond_to?(:scenario) && child.scenario

      scenario = child.scenario
      {
        feature_name: feature_name,
        feature_tags: feature_tags,
        line: scenario.location.line,
        column: scenario.location.column,
        name: scenario.name,
        tags: scenario.tags.map(&:name).map { |tag| tag.delete_prefix("@") }
      }
    end
  end
end
