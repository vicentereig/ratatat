# Ratatat: Textual-Inspired Features Implementation Plan

This document tracks the implementation of Textual-like features in Ratatat.
Each phase builds on the previous, with clear milestones and acceptance criteria.

## Textual Core Philosophy

> **"Attributes Down, Messages Up"**
> - Parents set child attributes or call child methods directly
> - Children communicate to parents ONLY via messages
> - Siblings communicate through parent intermediary

This pattern is fundamental to Textual's architecture and should guide all design decisions.

## Current State

Ratatat has:
- FFI bindings to Ratatui/Crossterm (working)
- Basic render loop with polling
- 4 simple widgets (List, Detail, Footer, Split)
- Hardcoded event handling in App class

## Implementation Phases

---

## Phase 0: Pure Ruby Rendering Engine (No FFI)

**Goal**: Replace Ratatui FFI with pure Ruby terminal I/O + cell-based diffing.

See: `docs/research/diffing-algorithms.md` for full algorithm analysis.

### 0.1 Cell Class
- [ ] `Ratatat::Cell` with symbol, fg, bg, modifiers, skip
- [ ] Equality based on visual appearance
- [ ] `EMPTY` constant for blank cells
- [ ] Support for multi-width characters (emoji, CJK)

```ruby
# Target API
class Cell
  attr_accessor :symbol, :fg, :bg, :modifiers, :skip

  EMPTY = Cell.new(symbol: " ", fg: :reset, bg: :reset)

  def ==(other)
    symbol == other.symbol && fg == other.fg &&
      bg == other.bg && modifiers == other.modifiers
  end

  def width
    Unicode::DisplayWidth.of(symbol)
  end
end
```

### 0.2 Buffer Class
- [ ] 2D grid stored as flat array (y * width + x indexing)
- [ ] `[]` and `[]=` for cell access
- [ ] `put_string(x, y, text, style)` helper
- [ ] `diff(other)` returns `[(x, y, cell), ...]` of changes
- [ ] Multi-width character invalidation tracking

```ruby
# Target API
class Buffer
  def initialize(width, height)
  def [](x, y) -> Cell
  def []=(x, y, cell)
  def put_string(x, y, text, fg: nil, bg: nil, **mods)
  def diff(other) -> Array<[x, y, Cell]>
  def clear
  def resize(new_width, new_height)
end
```

### 0.3 Color Support
- [ ] Named colors: `:black`, `:red`, `:green`, ..., `:white`
- [ ] Bright variants: `:bright_red`, etc.
- [ ] 256-color: `Color.indexed(196)`
- [ ] True color: `Color.rgb(255, 128, 0)` or `Color.hex("#ff8000")`
- [ ] `:reset` for default terminal color

```ruby
# Target API
module Color
  RESET = :reset
  BLACK = :black
  # ... 16 standard colors

  def self.indexed(n) -> IndexedColor
  def self.rgb(r, g, b) -> RgbColor
  def self.hex(str) -> RgbColor
end
```

### 0.4 ANSI Backend
- [ ] `draw(updates)` - batched output from diff
- [ ] Cursor movement optimization (skip if adjacent)
- [ ] Color change batching (only emit on change)
- [ ] Modifier change batching
- [ ] Single `write()` call for all updates

```ruby
# Target API
class AnsiBackend
  def draw(updates)     # [(x, y, cell), ...]
  def move_to(x, y)
  def show_cursor
  def hide_cursor
  def clear
  def flush
end
```

### 0.5 Terminal Class (Double Buffering)
- [ ] Two buffers: current and previous
- [ ] `draw { |buffer| ... }` block API
- [ ] `flush` computes diff and sends to backend
- [ ] `swap_buffers` after flush
- [ ] Auto-resize detection

```ruby
# Target API
class Terminal
  def initialize(backend: AnsiBackend.new)
  def draw { |frame| widgets.render(frame) }
  def flush  # diff + backend.draw + swap
  def size -> [rows, cols]
end
```

### 0.6 Pure Ruby Input
- [ ] Raw mode via `io/console`
- [ ] Non-blocking read with `IO.select`
- [ ] Parse escape sequences (arrows, function keys, modifiers)
- [ ] Timeout support for polling

```ruby
# Target API
class Input
  def initialize(io: $stdin)
  def poll(timeout_sec) -> KeyEvent | nil
  def read_blocking -> KeyEvent
end

class KeyEvent
  attr_reader :key        # :up, :down, :enter, "a", "A", etc.
  attr_reader :modifiers  # Set[:ctrl, :alt, :shift]
end
```

### 0.7 Driver Interface (Unified API)
- [ ] Abstract interface for Terminal + Input
- [ ] `Ffi` driver (existing, for comparison)
- [ ] `Native` driver (new pure Ruby)
- [ ] `Null` driver (for testing)

```ruby
# Target API
class Driver::Native
  def open     # Enter raw mode, alternate screen
  def close    # Restore terminal
  def render(widget_output)  # Widget renders to buffer
  def poll_event(timeout_ms) -> Event | nil
  def size -> [rows, cols]
end
```

### 0.8 Async Integration (Optional)
- [ ] Explore `async` gem for event loop
- [ ] Non-blocking input with Fiber
- [ ] Timer support without threads

**Acceptance Criteria**:
- [ ] Log tailer runs with pure Ruby driver (no FFI)
- [ ] No visible flicker during updates
- [ ] Performance: 60fps on 80x24 terminal
- [ ] Tests pass with Null driver
- [ ] Benchmark: diff 1920 cells in <1ms

**Dependencies**:
- `sorbet-runtime` gem (for type safety with T::Struct, T::Enum)
- `unicode-display_width` gem (for wide char support)
- Optional: `async` gem (for non-blocking I/O)

**Type Safety Guidelines**:
- Use `T::Struct` for immutable data classes (Cell, KeyEvent, Color types)
- Use `T::Enum` for finite sets of values (Modifier flags, named colors)
- Add `# typed: strict` to all new files
- Use `sig` for method signatures on public APIs

---

## Phase 1: Message-Driven Architecture

**Goal**: Replace hardcoded event handling with a message-passing system.

### 1.1 Message Base Class
- [ ] Create `Ratatat::Message` base class
  - Properties: `sender`, `time`, `bubble` (default: true)
  - Methods: `stop` (halt propagation), `prevent_default` (suppress default handler)
- [ ] Messages can be nested as inner classes of widgets (namespaced)
- [ ] Handler naming convention: `on_<message_name>` (e.g., `on_key`, `on_button_pressed`)

```ruby
# Target API
module Ratatat
  class Message
    attr_reader :sender, :time
    attr_accessor :bubble

    def initialize(sender:, bubble: true)
      @sender = sender
      @time = Time.now
      @bubble = bubble
      @stopped = false
      @prevented = false
    end

    def stop = @stopped = true
    def stopped? = @stopped
    def prevent_default = @prevented = true
    def prevented? = @prevented
  end

  # Input events
  class Key < Message
    attr_reader :key, :modifiers  # modifiers: [:ctrl, :alt, :shift]
  end

  class Resize < Message
    attr_reader :width, :height
  end

  # Widget-specific messages are nested
  class Button < Widget
    class Pressed < Message; end  # Handler: on_button_pressed
  end
end
```

### 1.2 Message Queue
- [ ] Create `Ratatat::MessageQueue` (thread-safe, FIFO)
- [ ] Each widget has its own message queue (like Textual's MessagePump)
- [ ] `post_message(message)` adds to queue
- [ ] Messages processed sequentially in order received

### 1.3 Message Dispatch & Bubbling
- [ ] Process messages in DOM order: focused widget first, then ancestors
- [ ] Call `on_<message_name>(message)` on each widget
- [ ] If handler calls `message.stop`, stop bubbling
- [ ] Bubbling only occurs if `message.bubble == true`

### 1.4 Refactor App#run
- [ ] Remove hardcoded `case` statement entirely
- [ ] Poll driver → create Message objects → post to queue
- [ ] Process queue → dispatch to widget tree
- [ ] Render after message batch processed

**Acceptance**: Log tailer example works with message-based events, no hardcoded handlers.

---

## Phase 2: Widget Tree & DOM

**Goal**: Widgets form a traversable DOM tree with identity and focus.

### 2.1 Widget Base Class
- [ ] Create `Ratatat::Widget` base class (all widgets inherit)
- [ ] Identity: `id` (unique string), `classes` (Set of strings)
- [ ] Tree: `parent`, `children` array
- [ ] Built-in reactive properties: `disabled`, `has_focus`, `visible`
- [ ] Class-level config: `CAN_FOCUS = false`, `FOCUS_ON_CLICK = true`

```ruby
# Target API
class Widget
  CAN_FOCUS = false
  FOCUS_ON_CLICK = true

  attr_reader :id, :parent, :children
  attr_accessor :classes

  # Reactive (Phase 5) - but define interface now
  # disabled, has_focus, visible

  def can_focus? = self.class::CAN_FOCUS && !disabled
  def focus_on_click? = self.class::FOCUS_ON_CLICK
end
```

### 2.2 DOM Tree Operations
- [ ] `mount(*widgets)` - add children, triggers `on_mount`
- [ ] `remove` - remove self from parent, triggers `on_unmount`
- [ ] `move_child(widget, before:)` - reorder children
- [ ] Tree traversal: `ancestors`, `descendants`, `siblings`
- [ ] `walk_children` - depth-first traversal

### 2.3 Focus System
- [ ] App/Screen tracks single focused widget
- [ ] Only widgets with `can_focus? == true` receive focus
- [ ] `focus` - request focus for this widget
- [ ] `blur` - remove focus from this widget
- [ ] Tab order follows DOM order (depth-first)
- [ ] Tab/Shift+Tab navigation through focusable widgets
- [ ] Focused widget receives Key messages first (before bubbling)

### 2.4 Basic Query System
- [ ] `query(selector)` - returns array of matching widgets
- [ ] `query_one(selector)` - returns first match or nil
- [ ] `query_one!(selector)` - returns first match or raises
- [ ] Selectors: `#id`, `.class`, `WidgetType`

```ruby
# Target API
self.query("#sidebar")           # By ID
self.query(".active")            # By class
self.query(Button)               # By type (Ruby class)
self.query_one!("#submit", Button)  # Type-checked
```

**Acceptance**: Can focus different widgets with Tab, query by id/class/type works.

---

## Phase 3: Lifecycle Hooks

**Goal**: Widgets have predictable lifecycle with hook methods.

### 3.1 Lifecycle Order (matches Textual)
1. `on_load` - Before terminal mode, non-visual setup only
2. `on_mount` - After added to DOM, safe to query siblings/children
3. `compose` - Framework calls to create children (Phase 6)
4. `on_show` - Before widget becomes visible
5. `on_ready` - App-level only, after first render complete

```ruby
# Target API
class MyWidget < Widget
  def on_load
    # Bind extra keys, setup before terminal mode
  end

  def on_mount
    # Query children, set timers, initialize state
    set_interval(1.0) { refresh }
    query_one("#input").focus
  end

  def on_show
    # About to be displayed
  end
end

class MyApp < App
  def on_ready
    # First frame rendered, app fully initialized
    log "App ready!"
  end
end
```

### 3.2 Unmount & Cleanup
- [ ] `on_unmount` - called when widget removed from DOM
- [ ] Cancel timers, cleanup resources

### 3.3 Focus Lifecycle
- [ ] `on_focus` - widget gained focus (receives Focus message)
- [ ] `on_blur` - widget lost focus (receives Blur message)

### 3.4 Resize Handling
- [ ] `on_resize(width, height)` - terminal resized
- [ ] Propagate through widget tree

**Acceptance**: Widgets initialize in on_mount, cleanup in on_unmount, lifecycle order correct.

---

## Phase 4: Declarative Key Bindings

**Goal**: Define key bindings as class-level declarations (like Textual's BINDINGS).

### 4.1 BINDINGS Constant
- [ ] Class-level `BINDINGS` array of tuples or Binding objects
- [ ] Format: `[key, action, description]` or `Binding.new(...)`
- [ ] Actions map to `action_*` methods (not just method names)

```ruby
# Target API
class MyWidget < Widget
  BINDINGS = [
    ["q", "quit", "Quit application"],
    ["up,k", "move_up", "Move cursor up"],  # Multiple keys
    Binding.new("ctrl+s", "save", "Save file", show: true, priority: false),
  ]

  def action_quit
    app.exit
  end

  def action_move_up
    @cursor -= 1
  end

  def action_save
    save_file
  end
end
```

### 4.2 Binding Class
- [ ] `key` - key combo string ("ctrl+s", "up", "f1")
- [ ] `action` - action method name (without `action_` prefix)
- [ ] `description` - user-visible text
- [ ] `show` - display in help/footer (default: true)
- [ ] `priority` - check before focused widget (default: false)

### 4.3 Binding Resolution Order
1. Priority bindings (any widget with `priority: true`)
2. Focused widget's BINDINGS
3. Bubble up through ancestors
4. App-level BINDINGS (fallback)

### 4.4 Inheritance & Dynamic Bindings
- [ ] Subclasses inherit parent BINDINGS
- [ ] `bind(key, action, description)` - add binding at runtime
- [ ] `unbind(key)` - remove binding at runtime

**Acceptance**: Widgets declare BINDINGS, action_* methods called, priority works.

---

## Phase 5: Reactive Properties

**Goal**: Properties that trigger callbacks and auto-refresh when changed.

### 5.1 Reactive DSL
- [ ] `reactive` class method to declare watched properties
- [ ] Parameters: `default:`, `repaint:` (auto-refresh), `layout:`, `recompose:`
- [ ] Generates getter/setter with change detection

```ruby
# Target API
class Counter < Widget
  reactive :count, default: 0, repaint: true
  reactive :items, default: [], recompose: true  # Rebuilds children

  # Called in order: validate → compute → watch
end
```

### 5.2 Three-Method Pattern (Textual's approach)
- [ ] `validate_<name>(value)` - intercept/transform before storage, return new value
- [ ] `compute_<name>` - derive value from other reactives (cached)
- [ ] `watch_<name>(old_value, new_value)` - respond to changes with side effects

```ruby
# Target API
class Counter < Widget
  reactive :count, default: 0

  def validate_count(value)
    value.clamp(0, 100)  # Constrain to range
  end

  def compute_display
    "Count: #{count}"  # Derived from :count
  end

  def watch_count(old_value, new_value)
    log "Count changed: #{old_value} → #{new_value}"
    play_sound if new_value > old_value
  end
end
```

### 5.3 Automatic Behaviors
- [ ] `repaint: true` - call `refresh` on change (default: true)
- [ ] `layout: true` - trigger layout recalculation
- [ ] `recompose: true` - rebuild widget children
- [ ] Changes batched for efficiency (don't render mid-batch)

### 5.4 Mutation Helpers
- [ ] `mutate_reactive(:items)` - notify watchers after mutating collection
- [ ] Needed because `items << x` doesn't trigger setter

**Acceptance**: Reactive changes trigger watchers, auto-refresh works, validation works.

---

## Phase 6: Declarative Composition

**Goal**: Widgets declare children via compose method (like Textual).

### 6.1 Compose Method
- [ ] Override `compose` to yield children via Enumerator
- [ ] Called automatically after mount, before first render
- [ ] Children mounted in order yielded

```ruby
# Target API (Ruby Enumerator pattern)
class MyApp < App
  def compose
    Enumerator.new do |y|
      y << Header.new("My App")
      y << Container.new(id: "main") do |c|
        c << Sidebar.new
        c << Content.new
      end
      y << Footer.new
    end
  end
end

# Or simpler array-based approach:
class MyApp < App
  def compose
    [
      Header.new("My App"),
      Split.new(
        left: Sidebar.new,
        right: Content.new,
        ratio: 0.3
      ),
      Footer.new
    ]
  end
end
```

### 6.2 Conditional Composition
- [ ] Compose can include conditionals based on state
- [ ] Use `recompose: true` reactive to trigger rebuild

### 6.3 Dynamic Mounting
- [ ] `mount(*widgets)` - add children after initial compose
- [ ] `mount_all(widgets)` - batch mount
- [ ] Batch updates to avoid flicker: `batch { mount(a); mount(b) }`

### 6.4 Recompose
- [ ] Reactive with `recompose: true` triggers full rebuild
- [ ] All children removed, compose called again
- [ ] State preserved where possible (match by id)

**Acceptance**: Apps define structure via compose, dynamic mount works, recompose triggers.

---

## Phase 7: Styling System (TCSS-inspired)

**Goal**: CSS-like styling for widgets.

### 7.1 Style Properties
- [ ] Dimensions: `width`, `height`, `min_width`, `max_width`, etc.
- [ ] Spacing: `padding`, `margin` (can be `[top, right, bottom, left]`)
- [ ] Colors: `background`, `foreground` (color names, hex, RGB)
- [ ] Borders: `border` (style + color), `border_title`
- [ ] Text: `bold`, `italic`, `underline`, `text_align`
- [ ] Layout: `display`, `overflow`

### 7.2 Inline Styles
- [ ] Widgets accept `styles:` hash in constructor
- [ ] `widget.styles.background = :red` - programmatic access

```ruby
# Target API
Button.new("Submit", styles: { background: :blue, padding: [0, 2] })

# Programmatic
widget.styles.background = :red
widget.styles.width = "50%"
```

### 7.3 Style Classes & Selectors
- [ ] Define styles in App: `CSS` constant or `CSS_PATH` file
- [ ] Selector types: type (`Button`), id (`#submit`), class (`.primary`)
- [ ] Pseudo-classes: `:focus`, `:hover`, `:disabled`
- [ ] Combinators: descendant (`A B`), child (`A > B`)

```ruby
# Target API
class MyApp < App
  CSS = <<~TCSS
    Button {
      background: blue;
      padding: 0 2;
    }

    Button:focus {
      background: cyan;
    }

    #submit {
      background: green;
    }

    .error {
      foreground: red;
    }

    Dialog Button {
      margin: 1;
    }
  TCSS
end
```

### 7.4 Class Management
- [ ] `add_class(name)` / `remove_class(name)` / `toggle_class(name)`
- [ ] `set_class(condition, name)` - add if true, remove if false
- [ ] Multiple classes combine (later wins for conflicts)

### 7.5 Specificity (CSS Cascade)
1. Inline styles (highest)
2. ID selectors
3. Class selectors
4. Type selectors (lowest)

**Acceptance**: Widgets styled via CSS string, focus changes style, classes work.

---

## Phase 8: Rich Widget Library

**Goal**: Provide common UI widgets out of the box.

### 8.1 Text Input Widgets
- [ ] `Input` - single line text input with cursor
- [ ] `TextArea` - multi-line text input
- [ ] Selection, copy/paste support

### 8.2 Button & Actions
- [ ] `Button` - clickable, emits `Button::Pressed` message
- [ ] Keyboard activation via Enter/Space when focused
- [ ] Variants/styles: default, primary, warning, error

### 8.3 Selection Widgets
- [ ] `Select` / `SelectionList` - choose from options
- [ ] `RadioSet` - exclusive selection
- [ ] `Checkbox` / `Switch` - boolean toggle

### 8.4 Data Display
- [ ] `DataTable` - sortable, scrollable table with columns
- [ ] `Tree` - expandable hierarchical view
- [ ] `ProgressBar` - progress indicator
- [ ] `Sparkline` - inline chart
- [ ] `Log` - scrolling log viewer

### 8.5 Layout Widgets
- [ ] `Container` - generic box
- [ ] `Horizontal` / `Vertical` - flex-like layout
- [ ] `Grid` - grid layout
- [ ] `ScrollableContainer` - scrollable viewport
- [ ] `TabbedContent` - tabbed panels

### 8.6 Overlay Widgets
- [ ] `Modal` / `ModalScreen` - dialog overlay
- [ ] `Toast` / `Notification` - temporary message
- [ ] `Tooltip` - contextual help

**Acceptance**: Can build complex UIs using provided widget library.

---

## Phase 9: Async & Timers

**Goal**: Non-blocking operations and scheduled callbacks.

### 9.1 Timer Methods (on App and Widget)
- [ ] `set_timer(delay, &block)` - one-shot timer, returns timer ID
- [ ] `set_interval(period, &block)` - repeating timer, returns timer ID
- [ ] `cancel_timer(id)` - cancel a timer
- [ ] Callbacks run on main thread (safe to update UI)

```ruby
# Target API
def on_mount
  @timer_id = set_interval(1.0) { update_clock }
end

def on_unmount
  cancel_timer(@timer_id)
end
```

### 9.2 Deferred Execution
- [ ] `call_next(&block)` - run immediately after current handler
- [ ] `call_later(&block)` - run after message queue drained
- [ ] `call_after_refresh(&block)` - run after next render

### 9.3 Background Workers
- [ ] `run_worker(name) { long_operation }` - run in thread
- [ ] Worker posts result message back to main thread
- [ ] `Worker::Done` message with result

```ruby
# Target API
def load_data
  run_worker(:loader) do
    fetch_from_api  # Runs in background
  end
end

def on_worker_done(message)
  return unless message.worker == :loader
  @data = message.result
  refresh
end
```

### 9.4 Thread Safety
- [ ] All UI modifications must happen on main thread
- [ ] Workers communicate via messages only
- [ ] Document thread-safety requirements

**Acceptance**: Timers work, background workers complete and update UI.

---

## Phase 10: Advanced Query System

**Goal**: Full CSS-like selector support with bulk operations.

### 10.1 Compound Selectors
- [ ] `Button.primary` - type + class
- [ ] `#sidebar .item` - descendant
- [ ] `Container > Button` - direct child only
- [ ] `Button:focus` - with pseudo-class
- [ ] `:not(.disabled)` - negation

### 10.2 DOMQuery Object
- [ ] `query()` returns DOMQuery (not plain array)
- [ ] List-like: indexing, slicing, iteration, `length`
- [ ] `first` / `last` - first/last match
- [ ] `filter(selector)` - narrow results
- [ ] `exclude(selector)` - remove matches

```ruby
# Target API
buttons = query("Button")
buttons[0]              # First button
buttons.first           # Same
buttons.last            # Last button
buttons.filter(".active")  # Only active buttons
buttons.exclude(".disabled")  # Skip disabled
```

### 10.3 Bulk Operations
- [ ] `add_class(name)` / `remove_class(name)` / `toggle_class(name)`
- [ ] `refresh` - refresh all matched widgets
- [ ] `remove` - remove all matched widgets
- [ ] `focus` - focus first matched widget
- [ ] `set_styles(...)` - apply styles to all

```ruby
# Target API
query(".item").add_class("selected")
query("Button.old").remove
query("#search").focus
```

**Acceptance**: Complex selectors work, bulk operations apply to all matches.

---

## Implementation Priority

Recommended order based on dependencies:

0. **Phase 0: Pure Ruby Rendering** - Foundation: flicker-free output, no FFI
1. **Phase 1: Messages** - Event system foundation
2. **Phase 2: Widget Tree** - DOM structure, focus, basic queries
3. **Phase 3: Lifecycle** - Proper init/cleanup patterns
4. **Phase 4: Key Bindings** - High value, builds on messages
5. **Phase 5: Reactive** - Clean state management
6. **Phase 6: Composition** - Declarative structure
7. **Phase 7: Styling** - Visual polish
8. **Phase 8: Widget Library** - Build out components
9. **Phase 9: Async** - Timers and workers
10. **Phase 10: Advanced Queries** - Power user feature

---

## Progress Tracking

| Phase | Status | Started | Completed |
|-------|--------|---------|-----------|
| 0. Pure Ruby Rendering | Done | 2025-11-27 | 2025-11-27 |
| 1. Messages | Done | 2025-11-27 | 2025-11-27 |
| 2. Widget Tree | Done | 2025-11-27 | 2025-11-27 |
| 3. Lifecycle | Done | 2025-11-27 | 2025-11-27 |
| 4. Key Bindings | Done | 2025-11-27 | 2025-11-27 |
| 5. Reactive | Not Started | | |
| 6. Composition | Not Started | | |
| 7. Styling | Not Started | | |
| 8. Widget Library | Not Started | | |
| 9. Async | Not Started | | |
| 10. Queries | Done | 2025-11-27 | 2025-11-27 |

---

## Design Notes

### Thread Safety
- Ratatat apps are NOT thread-safe (like Textual)
- All UI modifications must happen on main thread
- Use `call_next`, `call_later`, workers for async operations

### Performance Considerations
- `render` called frequently - keep it fast
- Reactive changes batched automatically
- Query results can be cached
- Use virtual scrolling for large data sets

### Ruby vs Python Differences
- No asyncio - use threads + message queue instead
- Blocks instead of async/await for callbacks
- Enumerator or Array for compose (not generator)
- Mixins/modules for shared behavior

### Testing Strategy
- Null driver for headless testing
- Test message flow with mock widgets
- Snapshot testing for rendered output
- Integration tests with recorded interactions
