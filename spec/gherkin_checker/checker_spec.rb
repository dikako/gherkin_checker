# frozen_string_literal: true

require "spec_helper"
require "gherkin_checker"

RSpec.describe GherkinChecker::Checker do
  let(:config_file) { "gherkin_checker.yml" }
  let(:config_data) do
    {
      "feature_files_path" => "features",
      "mandatory_tags" => {
        "one_of" => ["Automated"],
        "must_be" => ["iOS"]
      }
    }
  end

  let(:config_instance) { instance_double(GherkinChecker::Config) }
  let(:parser_instance) { instance_double(GherkinChecker::Parser) }
  let(:validator_instance) { instance_double(GherkinChecker::Validator) }

  subject { described_class.new(config_file) }

  before do
    allow(GherkinChecker::Config).to receive(:new).with(config_file).and_return(config_instance)
    allow(GherkinChecker::Parser).to receive(:new).and_return(parser_instance)
    allow(GherkinChecker::Validator).to receive(:new).with(config_instance).and_return(validator_instance)

    allow(config_instance).to receive(:feature_files_path).and_return("features")
    allow(config_instance).to receive(:one_of_tags).and_return(["Automated"])
    allow(config_instance).to receive(:must_be_tags).and_return(["iOS"])
  end

  describe "#check_feature_files" do
    let(:feature_file) { "features/test.feature" }

    context "when config is missing required tags" do
      before do
        allow(config_instance).to receive(:one_of_tags).and_return(nil)
        allow(config_instance).to receive(:must_be_tags).and_return(nil)
      end

      it "logs warning and skips check" do
        expect(subject).to receive(:log_message).with(/Warning: The gherkin_checker.yml not define/, level: :warn)
        expect(subject).to receive(:log_message).with(/Skip gherkin checking/, level: :warn)
        subject.check_feature_files
      end
    end

    context "when scenarios pass validation" do
      let(:scenario_data) do
        [{
          feature_name: "Feature 1",
          scenario_name: "Scenario 1",
          column: 1,
          line: 5,
          error: nil
        }]
      end

      before do
        allow(Find).to receive(:find).with("features").and_yield(feature_file)
        allow(File).to receive(:extname).with(feature_file).and_return(".feature")
        allow(parser_instance).to receive(:parse).with(feature_file).and_return(scenario_data)
        allow(validator_instance).to receive(:validate).with(scenario_data.first).and_return([])
      end

      it "logs success message" do
        expect(subject).to receive(:log_message).with("All scenarios have the required tags.")
        subject.check_feature_files
      end
    end

    context "when parsing errors occur" do
      let(:scenario_data) do
        [{
          error: "Parse error",
          type: :syntax_error
        }]
      end

      before do
        allow(Find).to receive(:find).with("features").and_yield(feature_file)
        allow(File).to receive(:extname).with(feature_file).and_return(".feature")
        allow(parser_instance).to receive(:parse).with(feature_file).and_return(scenario_data)
      end

      it "reports syntax errors" do
        expect(subject).to receive(:log_message).with("Gherkin Checker found Error:", level: :error)
        expect(subject).to receive(:log_message).with("Syntax Error: Parse error", level: :error)
        subject.check_feature_files
      end
    end

    context "when validation errors occur" do
      let(:scenario_data) do
        [{
          feature_name: "Feature 1",
          feature_tags: [],
          scenario_name: "Scenario 1",
          scenario_tags: ["WrongTag"],
          column: 1,
          line: 5,
          error: nil
        }]
      end

      let(:validation_errors) do
        [{
          check: :one_of_tags,
          expected: ["Automated"],
          scenario_tags: ["WrongTag"],
          scenario_name: "Scenario 1",
          file_line: "5"
        }]
      end

      before do
        allow(Find).to receive(:find).with("features").and_yield(feature_file)
        allow(File).to receive(:extname).with(feature_file).and_return(".feature")
        allow(parser_instance).to receive(:parse).with(feature_file).and_return(scenario_data)
        allow(validator_instance).to receive(:validate).with(scenario_data.first).and_return(validation_errors)
      end

      it "reports validation errors" do
        error_msg = "features/test.feature:5:1: Scenario 1 - one_of_tags '[\"Automated\"]' not found!, " \
                    "Just found '[\"WrongTag\"]'"
        expect(subject).to receive(:log_message).with("Gherkin Checker found Error:", level: :error)
        expect(subject).to receive(:log_message)
          .with(error_msg, level: :error)
        subject.check_feature_files
      end
    end
  end
end
