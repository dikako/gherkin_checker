# frozen_string_literal: true
# gherkin_checker.gemspec

require_relative "lib/gherkin_checker/version"

Gem::Specification.new do |spec|
  spec.name = "gherkin_checker"
  spec.version = GherkinChecker::VERSION
  spec.summary = ".feature files checkers"
  spec.description = "Checking .feature files"
  spec.authors = ["Dikakoko"]
  spec.email = ["dikakoko@icloud.com"]

  spec.files = Dir["lib/**/*", "exe/*", "README.md"]
  spec.bindir = "exe"
  spec.executables = ["gherkin_checker"] # Name of the executable command
  spec.homepage = "https://github.com/dikako/gherkin_checker"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.0"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["source_code_uri"] = "https://github.com/dikako/gherkin_checker"
end
