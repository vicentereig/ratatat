module Ratatat
  class App
    def initialize(driver: Ratatat::Driver::Null.new, root:, rows: nil, cols: nil)
      @driver = driver
      @root = root
      @rows = rows
      @cols = cols
    end

    def run_once
      @driver.open
      frame = render_frame
      @driver.render(frame)
    ensure
      @driver.close
    end

    def run(interval: 0.1)
      @running = true
      trap("INT") { @running = false }
      @driver.open
      while @running
        case @driver.poll_event(25)
        when :quit
          @running = false
          next
        when :up
          @root&.move_cursor(-1) if @root.respond_to?(:move_cursor)
        when :down
          @root&.move_cursor(1) if @root.respond_to?(:move_cursor)
        when :toggle_follow
          @root&.toggle_follow if @root.respond_to?(:toggle_follow)
        end
        frame = render_frame
        @driver.render(frame)
        sleep interval
      end
    ensure
      @driver.close
    end

    def stop
      @running = false
    end

    def render_frame
      rows, cols = frame_size
      @root.render(rows: rows, cols: cols)
    end

    def frame_size
      if @driver.respond_to?(:size)
        driver_rows, driver_cols = @driver.size
        return [driver_rows, driver_cols] if driver_rows && driver_cols
      end
      [@rows || 24, @cols || 80]
    end
  end
end
