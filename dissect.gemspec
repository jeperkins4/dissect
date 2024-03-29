# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dissect/version'

Gem::Specification.new do |spec|
  spec.name          = "dissect"
  spec.version       = Dissect::VERSION
  spec.authors       = ["John Perkins"]
  spec.email         = ["jeperkins4@gmail.com"]
  spec.summary       = %q{A contextual search tool.}
  spec.description   = %q{Contextual search that returns matching items with their hierarchial information.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "stackprof"

  spec.add_runtime_dependency('activesupport')
  spec.add_runtime_dependency('fuzzy-string-match_pure')
end
