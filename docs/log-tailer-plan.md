# Plan: Split-Pane Log Tailing MVP

## Objective
Ship a minimal Textual-like Ruby gem backed by a Rust `cdylib` over ratatui, delivering a two-pane log viewer (tail + detail) to validate the DSL, message pump, and rendering pipeline.

## Target UX Slice
- Left pane: scrollable tail of stdin or a file; highlights cursor line.
- Right pane: detail view of the selected line (timestamp + pretty JSON when applicable).
- Key map: `j/k` line nav, `PgUp/PgDn`, `/` filter prompt (in-Ruby substring match), `q` quit, `?` help overlay.
- Status bar: file name, total lines, filter state, tick FPS.

## Architecture Approach
- Rust shim (`native/ratatat-ffi/`): owns terminal setup, tick/input pump, diffed rendering via ratatui; exposes C ABI for init, poll, render, shutdown.
- Ruby DSL (`lib/ratatat/`): `App`, `compose`, `List`, `DetailPane`, `Footer`; message/handler API (`on_key`, `on_tick`), state kept in Ruby.
- Rendering: Ruby builds a virtual widget tree → serialized instructions → Rust renders with ratatui; keep surface minimal (text spans, layout splits, colors).

## Work Breakdown
1) **FFI bootstrap**: `init(term_size)`, `poll_next_event(timeout_ms)`, `begin_frame()`, `draw(commands)`, `end_frame()`, `shutdown()`.
2) **Ruby runtime**: event loop bridging poll → dispatch → render; timer ticks; trap SIGINT for restore.
3) **Widgets**: `List` with virtualization window; `DetailPane` with wrapping; `Footer` with key hints; `Modal` for filter prompt.
4) **App DSL**: `class LogTailer < Ratatat::App; compose do ... end; on_key ... end`.
5) **Data plumbing**: tail reader (IO thread) pushing lines to channel; filter applied in Ruby; capped buffer size.
6) **Packaging**: `rake compile`, gemspec, version gate on Rust ABI.
7) **Docs & demo**: `examples/log_tailer.rb` and README section; asciinema/gif once stable.

## Testing
- Ruby: RSpec for DSL behaviors, key handling, filter logic; mock terminal surfaces.
- FFI contract: Rust tests for init/draw/shutdown; Ruby integration spec that feeds fake events and asserts buffer snapshots.
- No live TTY in CI; use deterministic fixtures.

## Milestones
- M1: FFI scaffold builds and exposes events.
- M2: Ruby event loop + static layout renders.
- M3: Keyboard nav + tail input hooked up.
- M4: Filter prompt + detail pane formatting.
- M5: Demo polish and docs.

## Risks / Watchpoints
- Keep ABI stable; pin ratatui version.
- Avoid panics across FFI; map errors to codes.
- Ensure redraw efficiency (virtualized list, minimal diff).
