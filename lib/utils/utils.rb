# frozen_string_literal: true

require_relative "../gherkin_checker"

class Utils
  class << self
    def generate_gherkin_checker_yml(config_file)
      generated_content = <<~YAML
      # Path to the feature files
      feature_files_path: './features'
    
      mandatory_tags:
        # Fill the Required tags below
        must_be:
          - "Example"
        # Optional tags, one of which must be checked
        one_of:
          - "Positive"
          - "Negative"
    YAML
      File.open(config_file, "w") do |file|
        file.write(generated_content)
      end
    rescue Errno::EACCES
      GherkinChecker::Checker.log_message("Error: Permission denied. Unable to write to the file. Please check your permission settings", level: :error)
    end
  end
end
