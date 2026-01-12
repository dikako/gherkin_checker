# frozen_string_literal: true

require "spec_helper"
require "gherkin_checker/validator"
require "gherkin_checker/config"

RSpec.describe GherkinChecker::Validator do
  let(:config) { instance_double(GherkinChecker::Config) }
  subject { described_class.new(config) }

  describe "#validate" do
    let(:scenario_data) do
      {
        line: 10,
        name: "Test Scenario",
        tags: %w[Web High]
      }
    end

    before do
      allow(config).to receive(:one_of_tags).and_return(nil)
      allow(config).to receive(:must_be_tags).and_return(nil)
    end

    context "when one_of_tags is configured" do
      before do
        allow(config).to receive(:one_of_tags).and_return(%w[Web Mobile])
      end

      it "returns no error if tag is present" do
        expect(subject.validate(scenario_data)).to be_empty
      end

      it "returns error if tag is missing" do
        scenario_data[:tags] = ["Other"]
        errors = subject.validate(scenario_data)
        expect(errors.size).to eq(1)
        expect(errors.first[:check]).to eq(:one_of_tags)
      end
    end

    context "when must_be_tags is configured" do
      before do
        allow(config).to receive(:must_be_tags).and_return(["High"])
      end

      it "returns no error if tag is present" do
        expect(subject.validate(scenario_data)).to be_empty
      end

      it "returns error if tag is missing" do
        scenario_data[:tags] = ["Web"]
        errors = subject.validate(scenario_data)
        expect(errors.size).to eq(1)
        expect(errors.first[:check]).to eq(:must_be_tags)
      end
    end
  end
end
