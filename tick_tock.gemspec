lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "tick_tock/version"

Gem::Specification.new do |spec|
  spec.name          = "tick_tock"
  spec.version       = TickTock::VERSION
  spec.authors       = ["Marc Siegel"]
  spec.email         = ["marc@usainnov.com"]

  spec.summary       = "TickTock is an easy Ruby library for timing code."
  spec.description   = "TickTock is an easy Ruby library for timing all sorts "\
                       "of code, including lazy and asynchronous code."
  spec.homepage      = "https://github.com/ms-ati/tick_tock"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.2.0"

  spec.add_runtime_dependency "values", ">= 1.8.0"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_development_dependency "benchmark-ips"
end
