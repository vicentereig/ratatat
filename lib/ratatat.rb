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
require_relative "ratatat/dom_query"
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
require_relative "ratatat/widgets/text_area"
require_relative "ratatat/widgets/radio_set"
require_relative "ratatat/widgets/sparkline"
require_relative "ratatat/widgets/log"
require_relative "ratatat/widgets/grid"
require_relative "ratatat/widgets/scrollable_container"
require_relative "ratatat/widgets/tabbed_content"
require_relative "ratatat/widgets/toast"
require_relative "ratatat/widgets/tooltip"
require_relative "ratatat/widgets/spinner"
require_relative "ratatat/widgets/horizontal"
require_relative "ratatat/widgets/vertical"

module Ratatat
end
