module Notes

  class Task
    attr_accessor :author, :date, :filename, :line_num,
                  :line, :flags, :context

    def initialize(options={})
      @author   = options[:author]
      @date     = options[:date]
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

      "  ln #{@line_num}: #{line.strip}"
    end

    def to_json
      {
       filename: @filename,
       line_num: @line_num,
       line:     @line,
       flags:    @flags,
       context:  @context,
       author:   @author,
       date:    @date
      }
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
        lines = File.readlines(filename).map(&:chomp)

        lines.each_with_index do |line, idx|
          matched_flags = matching_flags(line, flags)

          if matched_flags.any?
            task_options = {
              filename: filename,
              line_num: counter,
              line: line,
              flags: matched_flags,
              context: context_lines(lines, idx)
            }

            # See what we can get from git
            info = line_info(filename, idx)
            task_options[:author] = info[:author] if info[:author]
            task_options[:date]   = info[:date] if info[:date]
            tasks << Notes::Task.new(task_options)
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
      options = Notes::Options.defaults
      files   = Notes.valid_files(options)
      return for_files(files, options[:flags])
    end

    private

    # Return up to 5 lines following the line at idx
    def context_lines(lines, idx)
      ctx = []
      1.upto(5) do |i|
        num = idx+i
        break unless lines[num]
        ctx << lines[num]
      end
      ctx.join("\n")
    end

    # Information about a line from git (author, date, etc)
    #
    # filename - A String filename
    # idx - a 0-based line number
    #
    # Returns Hash
    def line_info(filename, idx)
      result = {}
      return result unless Notes.git?

      fields = Notes.blame(filename, idx+1)

      author = fields["author"]
      result[:author] = author if !author.nil? && !author.empty?

      time = fields["author-time"] # ISO 8601
      result[:date] = Time.at(time.to_i).to_s if !time.nil? && !time.empty?

      sha = fields["sha"]
      result[:sha] = sha if !sha.nil?

      result
    end
  end

end
