require_relative "ratatat/version"

# Core rendering engine (order matters for dependencies)
require_relative "ratatat/color"
require_relative "ratatat/cell"
require_relative "ratatat/buffer"
require_relative "ratatat/ansi_backend"
require_relative "ratatat/terminal"
require_relative "ratatat/input"

# Drivers
require_relative "ratatat/driver"

# Message system
require_relative "ratatat/message"
require_relative "ratatat/binding"
require_relative "ratatat/reactive"
require_relative "ratatat/widget"

# Application framework
require_relative "ratatat/app"

module Ratatat
end
