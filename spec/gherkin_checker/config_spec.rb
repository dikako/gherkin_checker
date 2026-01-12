# frozen_string_literal: true

require "spec_helper"
require "gherkin_checker/config"

RSpec.describe GherkinChecker::Config do
  let(:config_file) { "spec/fixtures/gherkin_checker.yml" }

  before do
    allow(File).to receive(:exist?).and_return(true)
    allow(YAML).to receive(:load_file).and_return({
                                                    "feature_files_path" => "./features",
                                                    "mandatory_tags" => {
                                                      "one_of" => %w[Tag1 Tag2],
                                                      "must_be" => ["MustTag"]
                                                    }
                                                  })
  end

  subject { described_class.new(config_file) }

  describe "#initialize" do
    it "loads configuration from file" do
      expect(subject.feature_files_path).to eq("./features")
      expect(subject.one_of_tags).to eq(%w[Tag1 Tag2])
      expect(subject.must_be_tags).to eq(["MustTag"])
    end

    context "when config file does not exist" do
      before do
        allow(File).to receive(:exist?).and_return(false)
      end

      it "sets defaults and nils" do
        expect(subject.feature_files_path).to eq("./features")
        expect(subject.one_of_tags).to be_nil
        expect(subject.must_be_tags).to be_nil
      end
    end
  end
end
