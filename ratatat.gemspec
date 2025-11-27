require_relative "lib/ratatat/version"

Gem::Specification.new do |spec|
  spec.name          = "ratatat"
  spec.version       = Ratatat::VERSION
  spec.authors       = ["Contributors"]
  spec.summary       = "Textual-like Ruby DSL backed by ratatui (Rust)"
  spec.files         = Dir["lib/**/*", "native/ratatat-ffi/**/*", "examples/**/*", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "sorbet-runtime", ">= 0.5"

  spec.add_development_dependency "rspec", ">= 3.12"
  spec.add_development_dependency "sorbet", ">= 0.5"
  spec.add_development_dependency "tapioca", ">= 0.11"
end
