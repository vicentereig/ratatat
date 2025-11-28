# Ratatat

> A pure Ruby TUI framework inspired by Python's Textual. Build terminal user interfaces with a reactive, component-based architecture. No FFI required.

Ratatat provides a Textual-like development experience in Ruby: reactive properties, CSS-like styling, message-driven communication, and a rich widget library. It uses double-buffered rendering with cell-based diffing for flicker-free 60+ fps output.

## Core Concepts

**Architecture**: "Attributes Down, Messages Up"
- Parents set child attributes or call child methods directly
- Children communicate to parents ONLY via messages (bubbling)
- Siblings communicate through parent intermediary

**Reactive Properties**: Declare with `reactive :name, default: value, repaint: true`. Changes automatically trigger re-renders.

**Widget Tree**: Apps compose widgets via `compose` method. Query with CSS-like selectors: `query("#id")`, `query(".class")`, `query(WidgetClass)`.

**Message System**: Key presses, focus changes, and custom events bubble up the tree. Handle with `on_<message_type>` methods.

## Quick Start

```ruby
require "ratatat"

class MyApp < Ratatat::App
  def compose
    [
      Ratatat::Vertical.new.tap do |v|
        v.mount(
          Ratatat::Static.new("Hello, World!"),
          Ratatat::Button.new("Click me", id: "btn")
        )
      end
    ]
  end

  def on_button_pressed(message)
    query_one("#btn").label = "Clicked!"
  end
end

MyApp.new.run
```

## Project Structure

- [lib/ratatat.rb](lib/ratatat.rb): Main entry point, requires all components
- [lib/ratatat/app.rb](lib/ratatat/app.rb): Application base class with event loop
- [lib/ratatat/widget.rb](lib/ratatat/widget.rb): Base widget class
- [lib/ratatat/buffer.rb](lib/ratatat/buffer.rb): Double-buffered rendering with diffing
- [lib/ratatat/cell.rb](lib/ratatat/cell.rb): Terminal cell (symbol, colors, modifiers)
- [lib/ratatat/terminal.rb](lib/ratatat/terminal.rb): Terminal abstraction layer
- [lib/ratatat/message.rb](lib/ratatat/message.rb): Message types (Key, Focus, Blur, Quit)
- [lib/ratatat/reactive.rb](lib/ratatat/reactive.rb): Reactive property system
- [lib/ratatat/dom_query.rb](lib/ratatat/dom_query.rb): jQuery-like chainable queries
- [lib/ratatat/styles.rb](lib/ratatat/styles.rb): Inline styling system
- [lib/ratatat/css_parser.rb](lib/ratatat/css_parser.rb): CSS stylesheet parser

## Widgets

Layout:
- [Vertical](lib/ratatat/widgets/vertical.rb): Stack children vertically with optional ratios
- [Horizontal](lib/ratatat/widgets/horizontal.rb): Stack children horizontally with optional ratios
- [Grid](lib/ratatat/widgets/grid.rb): CSS Grid-like layout
- [Container](lib/ratatat/widgets/container.rb): Generic container
- [ScrollableContainer](lib/ratatat/widgets/scrollable_container.rb): Scrollable viewport

Input:
- [Button](lib/ratatat/widgets/button.rb): Clickable button with variants
- [TextInput](lib/ratatat/widgets/text_input.rb): Single-line text input
- [TextArea](lib/ratatat/widgets/text_area.rb): Multi-line text editor
- [Checkbox](lib/ratatat/widgets/checkbox.rb): Toggle checkbox
- [RadioSet](lib/ratatat/widgets/radio_set.rb): Radio button group
- [Select](lib/ratatat/widgets/select.rb): Dropdown selection

Display:
- [Static](lib/ratatat/widgets/static.rb): Static text display
- [ProgressBar](lib/ratatat/widgets/progress_bar.rb): Progress indicator
- [Sparkline](lib/ratatat/widgets/sparkline.rb): Inline charts
- [Spinner](lib/ratatat/widgets/spinner.rb): Animated loading indicator
- [DataTable](lib/ratatat/widgets/data_table.rb): Tabular data display
- [Tree](lib/ratatat/widgets/tree.rb): Hierarchical tree view
- [Log](lib/ratatat/widgets/log.rb): Scrolling log output

Overlay:
- [Modal](lib/ratatat/widgets/modal.rb): Modal dialogs
- [Toast](lib/ratatat/widgets/toast.rb): Notification toasts
- [Tooltip](lib/ratatat/widgets/tooltip.rb): Hover tooltips
- [TabbedContent](lib/ratatat/widgets/tabbed_content.rb): Tabbed panels

## Examples

- [examples/log_tailer.rb](examples/log_tailer.rb): Two-pane log viewer with filtering

## Documentation

- [docs/textual-features-plan.md](docs/textual-features-plan.md): Full feature implementation plan and status

## API Patterns

### Creating Widgets

```ruby
class MyWidget < Ratatat::Widget
  CAN_FOCUS = true  # Enable focus for this widget

  reactive :count, default: 0, repaint: true

  def render(buffer, x:, y:, width:, height:)
    buffer.put_string(x, y, "Count: #{count}")
  end

  def on_key(message)
    case message.key
    when "up" then self.count += 1
    when "down" then self.count -= 1
    end
  end
end
```

### Key Bindings

```ruby
class MyApp < Ratatat::App
  BINDINGS = [
    Ratatat::Binding.new("q", "quit", "Quit application"),
    Ratatat::Binding.new("r", "refresh", "Refresh data"),
  ]

  def action_quit = exit
  def action_refresh = reload_data
end
```

### Async Operations

```ruby
# Timers
set_timer(2.0) { show_message("2 seconds passed") }
set_interval(1.0) { update_clock }

# Background workers
run_worker(:fetch_data) { HTTP.get(url) }

def on_worker_done(message)
  return unless message.name == :fetch_data
  self.data = message.result
end
```

### Querying Widgets

```ruby
query("#my-id")           # By ID
query(".my-class")        # By class
query(Button)             # By type
query_one("#unique")      # Single result
query(".items").remove    # Bulk operations
```

## Performance

Buffer diffing optimized for 60+ fps:
- 80x24 terminal: 0.6ms diff time
- 180x48 terminal: 2.6ms diff time
- Rendering: 1600+ fps achievable

## Optional

### Development

```bash
bundle install
bundle exec rspec           # Run tests (419 specs)
bundle exec ruby examples/log_tailer.rb  # Run example
```

### Colors

```ruby
# Named colors
Ratatat::Color::Named::Red
Ratatat::Color::Named::BrightBlue

# 256-color palette
Ratatat::Color::Indexed.new(196)

# True color (RGB)
Ratatat::Color::Rgb.new(255, 128, 0)
```

### Modifiers

```ruby
modifiers = Set.new([
  Ratatat::Modifier::Bold,
  Ratatat::Modifier::Italic,
  Ratatat::Modifier::Underline,
])
```
