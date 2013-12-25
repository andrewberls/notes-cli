module Notes

  COLORS = {
    'yellow' => 33
  }

  def self.colorize(color, str)
    "\e[#{COLORS[color]};1m#{str}\033[0m"
  end

  class Task
    attr_accessor :author, :date, :filename, :line_num,
                  :line, :flags, :context

    # TODO: git integration
    # git blame -L6,6 --line-porcelain lib/notes-cli/tasks.rb
    def initialize(options={})
      #@author   = options[:author]
      #@date     = options[:date]
      @filename = options[:filename]
      @line_num = options[:line_num]
      @line     = options[:line]
      @flags    = options[:flags]
      @context  = options[:context]
    end

    # Return a String in a format suitable for printing
    # to the console that includes the line number
    # and matched flag highlighted in color
    #
    # flag_regex: Regex of search flags constructed from parsed options
    #
    # TODO: different colors for different flags
    def format(flag_regex)
      line  = @line.gsub(flag_regex) do |flag|
        Notes.colorize('yellow', flag)
      end

      "  ln #{@line_num}: #{line}"
    end
  end


  module Tasks
    extend self

    # Return array of flags matched in a line
    #
    # line - A String to match against
    # flags - An Array of String flags to search for
    #
    # Returns Array of string flags found
    def matching_flags(line, flags)
      words = line.split(/\W/).map(&:upcase)
      words & flags.map(&:upcase)
    end

    # Parse a file and construct Task objects for each line matching
    # one of the patterns specified in `flags`
    #
    # filename - A String filename to read
    # flags - Array of String flags to match against
    #
    # Returns Array<Notes::Task>
    def for_file(filename, flags)
      counter = 1
      tasks   = []

      begin
        # TODO: this may be large, punt until later.
        lines = File.readlines(filename).map(&:chomp)

        lines.each_with_index do |line, idx|
          matched_flags = matching_flags(line, flags)

          #if flags.any? { |flag| line =~ /#{flag}/i }
          if matched_flags.any?
            tasks << Notes::Task.new(
              filename: filename,
              line_num: counter,
              line: line.strip,
              flags: matched_flags,
              context: context_lines(lines, idx)
            )
          end
          counter += 1
        end
      rescue
        # Error occurred reading the file (ex: invalid byte sequence in UTF-8)
        # Move on quietly
      end

      tasks
    end

    # Compute all tasks for a set of files and flags
    #
    # files - Array of String filenames
    # flags - Array of String flags to match against
    #
    # Returns a hash of filename -> Array<Notes::Task>
    def for_files(files, flags)
      result = {}
      files.each do |filename|
        tasks = Notes::Tasks.for_file(filename, flags)

        # TODO: testing shortnames
        filename = filename.gsub(Dir.pwd, '').gsub(/^\//, '')

        result[filename] = tasks
      end

      # Delete file listings with no tasks
      result.delete_if { |k, v| v.empty? }
    end

    # Return list of tasks using default file locations and flags
    # Returns a hash of filename -> Array<Notes::Task>
    def defaults
      # default_dir = defined?(Rails) ? Rails.root : Dir.pwd
      # options = Notes::Options.defaults(default_dir)

      options = Notes::Options.defaults
      files   = Notes.valid_files(options)
      return for_files(files, options[:flags])
    end


    private

    # Return up to 5 lines following the line at idx
    def context_lines(lines, idx)
      ctx = []
      1.upto(5) do |i|
        break unless lines[idx+i]
        ctx << lines[idx+i]
      end
      ctx.join("\n")
    end

  end

end
