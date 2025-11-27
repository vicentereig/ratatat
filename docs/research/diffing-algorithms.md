# Terminal Diffing Algorithms: Textual vs Ratatui

## Executive Summary

| Aspect | Ratatui | Textual |
|--------|---------|---------|
| **Approach** | Cell-based diffing | Region-based compositing |
| **Complexity** | ~54 lines core diff | ~500+ lines compositor |
| **Granularity** | Per-cell | Per-widget-region |
| **Best for** | Direct rendering | Complex widget layering |

**Recommendation**: Implement Ratatui-style cell diffing for Ratatat. It's simpler, proven, and sufficient for our needs.

---

## Ratatui's Algorithm (Recommended)

### Core Concept: Double Buffering + Cell Diff

```
Frame N:
  ┌─────────────────┐     ┌─────────────────┐
  │ Previous Buffer │     │ Current Buffer  │
  │ "Hello World   "│     │ "Hello Ruby!   "│
  │ (from frame N-1)│     │ (just rendered) │
  └─────────────────┘     └─────────────────┘
           │                       │
           └───────┬───────────────┘
                   ▼
              Diff Algorithm
                   │
                   ▼
         [(6,'R'), (7,'u'), (8,'b'), (9,'y'), (10,'!')]
                   │
                   ▼
              Terminal I/O
         (only 5 cells, not 80)
```

### Data Structures

```ruby
# Cell: smallest unit of terminal display
class Cell
  attr_accessor :symbol      # String (grapheme cluster)
  attr_accessor :fg          # Foreground color
  attr_accessor :bg          # Background color
  attr_accessor :modifiers   # Bold, italic, underline, etc.
  attr_accessor :skip        # Skip during diff (for images)

  EMPTY = Cell.new(symbol: " ", fg: :reset, bg: :reset)

  def ==(other)
    symbol == other.symbol &&
      fg == other.fg &&
      bg == other.bg &&
      modifiers == other.modifiers
  end
end

# Buffer: 2D grid of cells stored as flat array
class Buffer
  attr_reader :width, :height, :cells

  def initialize(width, height)
    @width = width
    @height = height
    @cells = Array.new(width * height) { Cell::EMPTY.dup }
  end

  def [](x, y)
    @cells[y * @width + x]
  end

  def []=(x, y, cell)
    @cells[y * @width + x] = cell
  end
end
```

### The Diff Algorithm (~50 lines of Ruby)

```ruby
class Buffer
  # Returns array of [x, y, cell] for cells that changed
  def diff(other)
    updates = []
    invalidated = 0  # Cells invalidated by multi-width chars
    to_skip = 0      # Cells to skip (trailing part of wide char)

    @cells.each_with_index do |prev_cell, i|
      curr_cell = other.cells[i]

      # Should we emit this cell?
      # 1. Not marked skip
      # 2. Changed OR invalidated by previous wide char
      # 3. Not a trailing cell of a wide char
      if !curr_cell.skip &&
         (curr_cell != prev_cell || invalidated > 0) &&
         to_skip == 0

        x = i % @width
        y = i / @width
        updates << [x, y, curr_cell]
      end

      # Track multi-width characters
      curr_width = curr_cell.symbol.each_grapheme_cluster.sum { |g|
        Unicode::DisplayWidth.of(g) rescue 1
      }
      prev_width = prev_cell.symbol.each_grapheme_cluster.sum { |g|
        Unicode::DisplayWidth.of(g) rescue 1
      }

      to_skip = [curr_width - 1, 0].max
      invalidated = [[curr_width, prev_width].max, invalidated].max - 1
      invalidated = [invalidated, 0].max
    end

    updates
  end
end
```

### Backend: Batched Terminal Output

```ruby
class AnsiBackend
  def draw(updates)
    return if updates.empty?

    output = StringIO.new
    last_x, last_y = nil, nil
    curr_fg, curr_bg = :reset, :reset
    curr_mods = Set.new

    updates.each do |x, y, cell|
      # OPTIMIZATION 1: Skip cursor move if adjacent
      unless last_x && last_y && x == last_x + 1 && y == last_y
        output << "\e[#{y + 1};#{x + 1}H"  # Move cursor (1-indexed)
      end
      last_x, last_y = x, y

      # OPTIMIZATION 2: Only emit color changes
      if cell.fg != curr_fg || cell.bg != curr_bg
        output << ansi_color(cell.fg, cell.bg)
        curr_fg, curr_bg = cell.fg, cell.bg
      end

      # OPTIMIZATION 3: Only emit modifier changes
      if cell.modifiers != curr_mods
        output << ansi_modifiers(curr_mods, cell.modifiers)
        curr_mods = cell.modifiers
      end

      # Write the character
      output << cell.symbol
    end

    # Reset at end
    output << "\e[0m"

    # Single write to terminal
    $stdout.write(output.string)
    $stdout.flush
  end

  private

  def ansi_color(fg, bg)
    # Build SGR sequence for colors
    codes = []
    codes << fg_code(fg) if fg != :reset
    codes << bg_code(bg) if bg != :reset
    codes.empty? ? "" : "\e[#{codes.join(';')}m"
  end
end
```

### Performance

- **Time**: O(n) diff + O(m) output, where n = buffer size, m = changes
- **Space**: O(m) for update list
- **Typical**: 80x24 = 1920 cells, usually 20-100 change per frame (1-5%)

---

## Textual's Algorithm (More Complex)

### Core Concept: Widget Geometry + Cuts & Chops

Textual doesn't diff cells directly. Instead:

1. **Track widget geometry** - each widget's position, size, clip region
2. **Dirty region tracking** - mark regions that need redraw
3. **Cuts & Chops** - divide screen into segments at widget boundaries
4. **Layer compositing** - top widget wins in each region

```
Screen with overlapping widgets:

  ┌─────────────────────────────┐
  │ Widget A                    │
  │    ┌──────────────────┐     │
  │    │ Widget B (on top)│     │
  │    └──────────────────┘     │
  └─────────────────────────────┘

Cuts on line 3: [0, 5, 20, 30]
                 │  │   │   │
                 │  │   │   └─ Widget A continues
                 │  │   └───── Widget B ends
                 │  └───────── Widget B starts
                 └──────────── Widget A starts

Chops: [A:0-5] [B:5-20] [A:20-30]
```

### Key Data Structures

```python
# Segment: styled text chunk (from Rich library)
class Segment(NamedTuple):
    text: str
    style: Style | None
    control: Sequence | None

# Strip: horizontal line of segments
class Strip:
    _segments: list[Segment]
    cell_length: int  # Total width in cells

# MapGeometry: widget's screen position
class MapGeometry(NamedTuple):
    region: Region      # x, y, width, height
    clip: Region        # Clipping boundary
    order: tuple        # Z-index for layering
    virtual_region: Region  # For scrolling
```

### The Compositor Algorithm

```python
def render_update(self):
    # 1. Calculate cuts (widget boundaries on each line)
    cuts = self.calculate_cuts()

    # 2. For each visible widget, render to Strips
    renders = []
    for widget, geometry in self.visible_map.items():
        strips = widget.render_lines(geometry.region)
        renders.append((geometry, strips))

    # 3. Sort by z-order (top widgets first)
    renders.sort(key=lambda r: r[0].order, reverse=True)

    # 4. Chop each strip at cut points
    chops = [[None] * len(cuts[y]) for y in range(height)]

    for geometry, strips in renders:
        for y, strip in enumerate(strips):
            for cut_idx, chop in divide_at_cuts(strip, cuts[y]):
                # First (top-most) wins
                if chops[y][cut_idx] is None:
                    chops[y][cut_idx] = chop

    # 5. Combine chops into final lines
    return combine_chops(chops)
```

### Why It's Complex

1. **Widget-aware**: Knows about overlapping, doesn't need z-buffer
2. **Partial updates**: Only redraws dirty regions, not just dirty cells
3. **Rich integration**: Works with styled Segments, not raw characters
4. **Spatial indexing**: O(1) widget visibility lookup

---

## Comparison

| Feature | Ratatui | Textual |
|---------|---------|---------|
| **Diff unit** | Cell | Widget region |
| **Buffer model** | Flat array of cells | Widget → geometry map |
| **Overlapping widgets** | Painter's algorithm (last write wins) | Z-ordered chops (explicit layering) |
| **Style tracking** | Per-cell | Per-segment |
| **Partial update** | Any changed cell | Dirty region tracking |
| **Implementation** | ~54 lines | ~500+ lines |
| **Dependencies** | None | Rich library |

### When Ratatui Wins

- Simple widget hierarchies
- Direct buffer manipulation
- Minimal dependencies
- Easy to understand/debug

### When Textual Wins

- Complex overlapping widgets (modals, dropdowns)
- Many widgets (spatial indexing)
- Styled text with Rich integration
- Widget-level dirty tracking

---

## Recommendation for Ratatat

**Use Ratatui's approach** because:

1. **Simpler**: ~50 lines of Ruby vs 500+ lines
2. **Sufficient**: Most TUIs don't have complex overlapping
3. **Composable**: Widgets render to buffer, diff handles output
4. **Debuggable**: Easy to inspect buffer state
5. **No flicker**: Double buffering + diff = no visible redraws

### Proposed Architecture

```
Widget Tree                 Ruby Layer (high-level)
    │
    ▼
render(buffer)              Widgets write to Buffer
    │
    ▼
Buffer (current)            Cell grid in memory
    │
    ├──── diff() ────▶ Updates [(x,y,cell), ...]
    │
    ▼
Buffer (previous)           Last frame's state
    │
    ▼
AnsiBackend.draw(updates)   Batched ANSI output
    │
    ▼
Terminal                    Single write() call
```

### Implementation Plan

1. **Cell class**: symbol, fg, bg, modifiers, skip flag
2. **Buffer class**: width × height grid, index helpers, diff()
3. **AnsiBackend**: batched cursor/color/modifier output
4. **Terminal class**: double buffering, swap, flush

---

## Multi-Width Character Handling

Both libraries handle wide characters (CJK, emoji):

```
"Hello" = 5 cells
"你好"  = 4 cells (2 chars × 2 cells each)
"👋"   = 2 cells

Buffer representation:
  Index:  0   1   2   3   4
  Cells: [你] [ ] [好] [ ] [!]
              ↑       ↑
         Continuation cells (empty but occupied)
```

The diff algorithm tracks:
- `to_skip`: cells to skip (trailing part of wide char)
- `invalidated`: cells that must redraw (wide char changed width)

---

## Flicker Prevention

Both libraries prevent flicker through:

1. **Double buffering**: Never clear screen, only update diffs
2. **Batched output**: All updates in single write() call
3. **No cursor jump**: Adjacent cells don't emit cursor moves
4. **Atomic flush**: Final flush() after all updates queued

```ruby
# BAD: Causes flicker
print "\e[2J"           # Clear screen (visible!)
widgets.each { |w| w.render_to_terminal }

# GOOD: No flicker
widgets.each { |w| w.render_to_buffer(current_buffer) }
updates = previous_buffer.diff(current_buffer)
backend.draw(updates)   # Single atomic write
swap_buffers
```

---

## Next Steps

1. [ ] Implement `Cell` class with equality
2. [ ] Implement `Buffer` class with diff algorithm
3. [ ] Implement `AnsiBackend` with batched output
4. [ ] Implement `Terminal` with double buffering
5. [ ] Add unicode-display_width gem for wide char support
6. [ ] Integration tests: render → diff → verify output
7. [ ] Benchmark: measure diff performance on 80x24, 120x40, 200x50
