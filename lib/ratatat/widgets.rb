module Ratatat
  module Widgets
    class List
      attr_reader :lines, :cursor

      def initialize(lines:, cursor:)
        @lines = lines
        @cursor = cursor
      end

      # Render a vertical list with a cursor marker.
      def render(rows:, cols:)
        zero_cursor = [@cursor - 1, 0].max
        offset = [zero_cursor - 1, 0].max
        max_offset = [@lines.length - rows, 0].max
        offset = [offset, max_offset].min

        slice = @lines.slice(offset, rows) || []
        slice = slice.map.with_index do |line, idx|
          absolute_index = offset + idx
          marker = absolute_index == zero_cursor ? "> " : "  "
          (marker + line)[0, cols]
        end

        # Ensure we always return exactly rows lines (pad with blanks).
        if slice.length < rows
          slice += Array.new(rows - slice.length) { " " * cols }
        end

        slice
      end
    end

    class Detail
      def initialize(text:)
        @text = text
      end

      def render(rows:, cols:)
        lines = []
        @text.split("\n", -1).each do |paragraph|
          next if paragraph.nil?
          wrap_line(paragraph, cols, lines)
        end
        lines += Array.new([rows - lines.length, 0].max) { "" }
        lines.first(rows)
      end

      private

      def wrap_line(text, cols, out)
        return out << "" if text.nil? || text.empty?
        current = ""
        text.split(/\s+/).each do |word|
          if current.empty?
            current = word
          elsif current.length + 1 + word.length <= cols
            current << " " << word
          else
            out << current[0, cols]
            current = word
          end
        end
        out << current[0, cols] unless current.empty?
      end
    end

    class Footer
      def initialize(text)
        @text = text
      end

      def render(rows:, cols:)
        line = @text.ljust(cols)[0, cols]
        [line] + Array.new([rows - 1, 0].max) { "" }
      end
    end

    class Split
      def initialize(left:, right:, ratio: 0.5, separator: "│")
        @left = left
        @right = right
        @ratio = ratio
        @separator = separator
      end

      def render(rows:, cols:)
        sep_width = @separator&.length.to_i
        available = [cols - sep_width, 0].max
        if @ratio
          left_cols = (available * @ratio).floor
          right_cols = available - left_cols
        else
          left_cols = available / 2
          right_cols = available - left_cols
        end

        left_lines = @left.render(rows: rows, cols: left_cols)
        right_lines = @right.render(rows: rows, cols: right_cols)

        rows.times.map do |idx|
          left = left_lines[idx] || ""
          right = right_lines[idx] || ""
          left = left.ljust(left_cols)[0, left_cols]
          right = right.ljust(right_cols)[0, right_cols]
          if sep_width > 0
            "#{left}#{@separator}#{right}"
          else
            "#{left}#{right}"
          end
        end
      end
    end
  end
end
