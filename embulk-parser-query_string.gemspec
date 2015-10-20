
Gem::Specification.new do |spec|
  spec.name          = "embulk-parser-query_string"
  spec.version       = "0.3.0"
  spec.authors       = ["yoshihara", "uu59"]
  spec.summary       = "Query String parser plugin for Embulk"
  spec.description   = "Parses Query String files read by other file input plugins."
  spec.email         = ["h.yoshihara@everyleaf.com", "k@uu59.org"]
  spec.licenses      = ["Apache2"]
  spec.homepage      = "https://github.com/treasure-data/embulk-parser-query_string"

  spec.files         = `git ls-files`.split("\n") + Dir["classpath/*.jar"]
  spec.test_files    = spec.files.grep(%r{^(test|spec)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'addressable'
  spec.add_development_dependency 'embulk', [">= 0.7.2", "< 1.0"]
  spec.add_development_dependency 'bundler', ['~> 1.0']
  spec.add_development_dependency 'everyleaf-embulk_helper'
  spec.add_development_dependency 'rake', ['>= 10.0']
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'test-unit'
  spec.add_development_dependency 'test-unit-rr'
  spec.add_development_dependency 'codeclimate-test-reporter'
end
