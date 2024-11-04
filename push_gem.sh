RUBY_GEM=$(gem build gherkin_checker.gemspec | grep 'File:' | awk '{print $2}')
gem set --api-key "$RUBYGEM_API_KEY"
gem push "$RUBY_GEM" --host https://rubygems.org
