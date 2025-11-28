require_relative "lib/ratatat/version"

Gem::Specification.new do |spec|
  spec.name          = "ratatat"
  spec.version       = Ratatat::VERSION
  spec.authors       = ["Vicente Reig Rincon de Arellano"]
  spec.email         = ["hey@vicente.services"]
  spec.summary       = "A pure Ruby TUI framework inspired by Textual"
  spec.description   = "Build terminal user interfaces with a reactive, component-based architecture. Features reactive properties, CSS-like styling, message-driven communication, and a rich widget library."
  spec.homepage      = "https://github.com/vicentereig/ratatat"
  spec.license       = "MIT"
  spec.files         = Dir["lib/**/*", "examples/**/*", "README.md"]
  spec.require_paths = ["lib"]

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/vicentereig/ratatat",
    "documentation_uri" => "https://github.com/vicentereig/ratatat#readme"
  }

  spec.add_runtime_dependency "sorbet-runtime", ">= 0.5"

  spec.add_development_dependency "rspec", ">= 3.12"
  spec.add_development_dependency "sorbet", ">= 0.5"
  spec.add_development_dependency "tapioca", ">= 0.11"
end
