# frozen_string_literal: true

require "spec_helper"
require "gherkin_checker/parser"

RSpec.describe GherkinChecker::Parser do
  subject { described_class.new }

  describe "#parse" do
    let(:feature_file) { "spec/fixtures/test.feature" }
    let(:feature_content) do
      <<~GHERKIN
        @FeatureTag
        Feature: Test Feature

          @ScenarioTag
          Scenario: Test Scenario
            Given something
      GHERKIN
    end

    before do
      allow(File).to receive(:read).with(feature_file).and_return(feature_content)
    end

    it "parses feature file and returns scenario data" do
      result = subject.parse(feature_file)
      expect(result.size).to eq(1)
      scenario = result.first
      expect(scenario[:feature_name]).to eq("Test Feature")
      expect(scenario[:feature_tags]).to include("FeatureTag")
      expect(scenario[:name]).to eq("Test Scenario")
      expect(scenario[:tags]).to include("ScenarioTag")
    end

    context "when parsing fails with Gherkin error" do
      let(:invalid_file) { "spec/fixtures/invalid.feature" }
      let(:invalid_content) { "Feature: Invalid\n  Scenario: Invalid\n    Given\n    When" }

      before do
        allow(File).to receive(:read).with(invalid_file).and_return(invalid_content)
        allow(Gherkin::Parser).to receive(:new).and_call_original
      end

      it "returns syntax error hash" do
        # We need to actually run the parser to get the exception, so we don't mock the parser here fully
        # or we mock the exception raising.
        # For simplicity, let's mock the exception raising to avoid dependency on exact parser version behavior
        # if we want unit test isolation, but integration testing with the real parser is better.

        # Let's write the file content to a temp file or just stub File.read
        # Since I am running inside a real environment, let's use the real parser behavior if possible.
        # But here I am stubbing File.read.

        # Actually, let's just stub the parser raising the exception to verify the catching logic.
        parser_double = instance_double(Gherkin::Parser)
        allow(Gherkin::Parser).to receive(:new).and_return(parser_double)

        error = Gherkin::ParserError.new("Test Error")
        allow(parser_double).to receive(:parse).and_raise(error)

        result = subject.parse(invalid_file)
        expect(result.size).to eq(1)
        expect(result.first[:error]).to eq("Test Error")
        expect(result.first[:type]).to eq(:syntax_error)
      end
    end

    context "when parsing fails with StandardError" do
      before do
        allow(File).to receive(:read).and_raise(StandardError, "File read error")
      end

      it "returns error hash" do
        result = subject.parse(feature_file)
        expect(result.size).to eq(1)
        expect(result.first[:error]).to eq("File read error")
        expect(result.first[:type]).to eq(:unknown_error)
      end
    end
  end
end
