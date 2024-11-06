# GherkinChecker

**GherkinChecker** is a tool for validating and enforcing rules on Gherkin `.feature` files. It allows users to set custom tag and structure requirements for feature files to maintain consistency and quality in test scenarios.

## Installation

Install the gem and add it to your application's Gemfile by running:

```sh
gem install gherkin_checker
````

## Usage

After successful installation, navigate to your project repository and create a configuration file named gherkin_checker.yml. Define your custom rules for Gherkin checking within this file. Below is a sample configuration format:

```yaml
feature_files_path: '{to/your/path}'
mandatory_tags:
  must_be:
    - "Text1"
  one_of:
    - "Text2"
    - "Text3"
    - "Text4"
```

**Configuration Parameters**

- **feature_files_path**: Specifies the path to the directory containing Gherkin feature files.
- **mandatory_tags**:
    - **must_be**: Tags that must be present in every feature file.
    - **one_of**: Tags where at least one must be present in each feature file.

To run Gherkin Checker on your project, execute the following command in the terminal:

```sh
gherkin_checker
````

This command will check your feature files according to the rules defined in gherkin_checker.yml and provide feedback based on any discrepancies found.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dikako/gherkin_checker. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/gherkin_checker/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the GherkinChecker project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/gherkin_checker/blob/main/CODE_OF_CONDUCT.md).