# Repository Guidelines

## Project Structure & Module Organization
- Reference architecture docs live in `docs/research/architecture-study.md`; keep them in sync with code.
- Ruby API (Textual-like DSL, widgets, app loop) belongs under `lib/`.
- Native shim in `native/ratatat-ffi/`: a single Rust `cdylib` exposing a C ABI over ratatui; keep public FFI symbols stable.
- Examples and smoke demos go in `examples/` (run via `bundle exec ruby examples/<name>.rb` once the gem builds).
- Helper scripts in `scripts/`; keep them executable and portable.

## Build, Test, and Development Commands
- Rust shim:
  - `cargo fmt -p ratatat-ffi` – format.
  - `cargo clippy -p ratatat-ffi --all-targets --all-features -D warnings` – lint.
  - `cargo test -p ratatat-ffi` – unit/integration tests for the FFI layer.
  - `cargo build -p ratatat-ffi --release` – produce the shared library for packaging.
- Ruby gem:
  - `bundle exec rubocop` – style.
  - `bundle exec rspec` – specs for the Ruby DSL and FFI contract tests.
  - `bundle exec rake compile` (if using `rake-compiler`/`magnus`) – build native extension and copy artifacts.
- Docs: `codespell docs` before doc-heavy PRs to catch typos.

## Coding Style & Naming Conventions
- Ruby: snake_case files and methods; CamelCase classes/modules; prefer small objects wrapping FFI calls; keep DSL method names verb-driven (`compose`, `on_key`, `layout`).
- Rust shim: `rustfmt` defaults; `#[no_mangle] extern "C"` for ABI; avoid panics across FFI—convert to error codes/Result wrappers; keep FFI types POD-friendly.
- Markdown: wrap at ~100 chars; use fenced command examples; place diagrams in `docs/`.

## Testing Guidelines
- Ruby specs validate widget behaviors and event flows without hitting a real TTY; mock terminals when possible.
- FFI contract tests exercise compiled `ratatat-ffi` end-to-end (startup, resize, paint, teardown); prefer deterministic fixtures over live TTY.
- Name tests by behavior, e.g., `renders_focus_ring_on_hover`.
- Avoid network or filesystem watchers in CI; gate long-running demos behind explicit opts.

## Commit & Pull Request Guidelines
- Commit messages: imperative, type-prefixed (`feat:`, `fix:`, `docs:`); keep changes atomic.
- PRs include: short summary, behavior change, commands/tests run, linked issue, and terminal recordings or screenshots for UI changes.
- Keep diffs focused; split refactors from feature work when possible.

## Security & Configuration Tips
- Do not commit built artifacts (`native/ratatat-ffi/target/`, `pkg/`, `.gem`, `.dylib/.so/.dll`); keep them in `.gitignore`.
- Never commit secrets; when configuration appears, provide `.env.example`.
- Prefer dependencies with permissive licenses (MIT/Apache-2); review transitive crates/gems before adding.
