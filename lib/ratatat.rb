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
require_relative "ratatat/styles"
require_relative "ratatat/css_parser"
require_relative "ratatat/widget"

# Application framework
require_relative "ratatat/app"

# Widgets
require_relative "ratatat/widgets/static"
require_relative "ratatat/widgets/button"
require_relative "ratatat/widgets/text_input"
require_relative "ratatat/widgets/container"
require_relative "ratatat/widgets/checkbox"
require_relative "ratatat/widgets/select"
require_relative "ratatat/widgets/data_table"
require_relative "ratatat/widgets/tree"
require_relative "ratatat/widgets/progress_bar"
require_relative "ratatat/widgets/modal"

module Ratatat
end
