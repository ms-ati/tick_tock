lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "tick_tock/version"

Gem::Specification.new do |spec|
  spec.name          = "tick_tock"
  spec.version       = TickTock::VERSION
  spec.authors       = ["Marc Siegel"]
  spec.email         = ["marc@usainnov.com"]

  spec.summary       = "TickTock wraps Ruby code in timing and logging easily!"
  spec.description   = "TickTock makes it easy to wrap your Ruby code to "\
                       "measure nested timings and to log them -- even when "\
                       "the code is asynchronous or lazy, so straight-forward "\
                       "blocks do not work. Versions follow SemVer."
  spec.homepage      = "https://github.com/ms-ati/tick_tock"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.3.0"

  spec.add_runtime_dependency "values", ">= 1.8.0"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_development_dependency "byebug"

  spec.add_development_dependency "benchmark-ips"
end
