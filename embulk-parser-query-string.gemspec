
Gem::Specification.new do |spec|
  spec.name          = "embulk-parser-query-string"
  spec.version       = "0.1.0"
  spec.authors       = ["uu59"]
  spec.summary       = "Query String parser plugin for Embulk"
  spec.description   = "Parses Query String files read by other file input plugins."
  spec.email         = ["k@uu59.org"]
  spec.licenses      = ["MIT"]
  # TODO set this: spec.homepage      = "https://github.com/k/embulk-parser-query-string"

  spec.files         = `git ls-files`.split("\n") + Dir["classpath/*.jar"]
  spec.test_files    = spec.files.grep(%r{^(test|spec)/})
  spec.require_paths = ["lib"]

  #spec.add_dependency 'YOUR_GEM_DEPENDENCY', ['~> YOUR_GEM_DEPENDENCY_VERSION']
  spec.add_development_dependency 'bundler', ['~> 1.0']
  spec.add_development_dependency 'rake', ['>= 10.0']
end
