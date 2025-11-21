require_relative "lib/ratatat/version"

Gem::Specification.new do |spec|
  spec.name          = "ratatat"
  spec.version       = Ratatat::VERSION
  spec.authors       = ["Contributors"]
  spec.summary       = "Textual-like Ruby DSL backed by ratatui (Rust)"
  spec.files         = Dir["lib/**/*", "native/ratatat-ffi/**/*", "examples/**/*", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "ffi", ">= 1.16"
  spec.add_development_dependency "rspec", ">= 3.12"
end
