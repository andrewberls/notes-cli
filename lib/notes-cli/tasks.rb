module Notes
  COLORS = {
    'yellow' => 33
  }

  def self.colorize(color, str)
    "\e[#{COLORS[color]};1m#{str}\033[0m"
  end

  class Task < Struct.new(:line_num, :line)
    # Return a String in a format suitable for printing
    # to the console that includes the line number
    # and matched flag highlighted in color
    #
    # TODO: different colors for different flags
    def format(flag_regex)
      line  = self.line.gsub(flag_regex) do |flag|
        Notes.colorize('yellow', flag)
      end

      "  ln #{self.line_num}: #{line}"
    end
  end


  module Tasks
    # Parse a file and construct Task objects for each line matching
    # one of the patterns specified in `flags`
    #
    # Returns Array<Notes::Task>
    def self.for_file(filename, flags)
      counter = 1
      tasks   = []

      begin
        File.read(filename).each_line do |line|
          if flags.any? { |flag| line =~ /#{flag}/i }
            tasks << Notes::Task.new(counter, line.strip)
          end
          counter += 1
        end
      rescue
        # Error occurred reading the file (ex. invalid byte sequence in UTF-8)
        # Move on quietly
      end

      tasks
    end

  end
end
