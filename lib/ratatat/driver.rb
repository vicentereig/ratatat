module Ratatat
  module Driver
    begin
      require "ffi"
    rescue LoadError
      # FFI gem not available; we'll rely on the Null driver only.
    end

    # A fallback driver that dumps frames to STDOUT; used for specs and when the native
    # shim is unavailable.
    class Null
      def initialize(io: $stdout)
        @io = io
        @rows, @cols = detect_size
      end

      def open; end
      def close; end

      def render(lines)
        @io.puts("\e[2J") # clear
        lines.each { |line| @io.puts(line) }
      end

      def poll_event(_timeout_ms = 16)
        nil
      end

      def size
        [@rows, @cols]
      end

      private

      def detect_size
        require "io/console"
        rows, cols = IO.console.winsize
        [rows || 24, cols || 80]
      rescue LoadError, NoMethodError
        [24, 80]
      end
    end

    # Native driver backed by ratatui via the Rust cdylib.
    if defined?(FFI)
      class Ffi
        extend FFI::Library

        def self.find_lib
          candidates = []
          candidates << ENV["RATATAT_NATIVE_PATH"] if ENV["RATATAT_NATIVE_PATH"]
          base = File.expand_path("../../native/ratatat-ffi/target/release", __dir__)
          candidates << File.join(base, "libratatat_ffi.dylib")
          candidates << File.join(base, "libratatat_ffi.so")
          candidates << "libratatat_ffi"
          candidates
        end

        begin
          ffi_lib(find_lib)

          class Context < FFI::Struct
            layout :ptr, :pointer
          end

          class RtEvent < FFI::Struct
            layout :kind, :int, :code, :uint, :modifiers, :uint
          end

          attach_function :rt_init, [], :pointer
          attach_function :rt_shutdown, [:pointer], :void
          attach_function :rt_render_lines, [:pointer, :pointer, :int], :void
          attach_function :rt_poll_event, [:pointer, :uint, RtEvent.by_ref], :bool
          attach_function :rt_size, [:pointer, :pointer, :pointer], :bool

          def initialize
            @ctx = self.class.rt_init
          end

          def open; end

          def close
            self.class.rt_shutdown(@ctx) if @ctx && !@ctx.null?
            @ctx = nil
          end

          def render(lines)
            joined = lines.join("\n") + "\0"
            ptr = FFI::MemoryPointer.from_string(joined)
            self.class.rt_render_lines(@ctx, ptr, lines.length)
          end

          def size
            rows_ptr = FFI::MemoryPointer.new(:uint)
            cols_ptr = FFI::MemoryPointer.new(:uint)
            if self.class.rt_size(@ctx, cols_ptr, rows_ptr)
              [rows_ptr.read_uint, cols_ptr.read_uint]
            else
              [nil, nil]
            end
          end

          MOD_CTRL = 0x1

          def poll_event(timeout_ms = 50)
            evt = RtEvent.new
            return nil unless self.class.rt_poll_event(@ctx, timeout_ms, evt)

            if evt[:kind] == 1
              code = evt[:code]
              mods = evt[:modifiers]
              if code == "q".ord || (code == "c".ord && (mods & MOD_CTRL) != 0)
                return :quit
              elsif code == "f".ord
                return :toggle_follow
              elsif code == 1001
                return :up
              elsif code == 1002
                return :down
              end
            end
            nil
          end
        rescue LoadError
          # Native library missing; degrade to null driver.
          def initialize
            raise LoadError, "libratatat_ffi not built; run cargo build -p ratatat-ffi --release"
          end
        end
      end
    end
  end
end
