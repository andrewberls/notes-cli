class Notes
  attr_accessor :options

  class << self

    # Parse ARGV into a directory and list of argument groups
    # For example, given ['app/', -f', 'refactor', 'broken', '--exclude', 'tmp', 'log']:
    # => [ 'app/', ['-f', 'refactor', 'broken'], ['--exclude', 'tmp', 'log'] ]
    def parse_argv(args)
      result = []
      buf    = []
      dir    = args.first

      if args.empty? || dir.start_with?("-")
        # No dir was passed, use current dir
        result << Dir.pwd
      else
        # Dir was passed in
        dir = Dir.pwd if dir == '.'
        result << dir
        args = args.drop(1)
      end

      args.each do |arg|
        if arg.start_with?('-')
          result << buf unless buf.empty?
          buf = []
        end
        buf << arg
      end

      result << buf
    end

    # Append any command line arguments to a default set of arguments
    # arg_list is a directory and argument groups parsed from ARGV. For example:
    # [ "app/", ['-f', 'refactor', 'broken'], ['--exclude', 'tmp', 'log'] ]
    def build_options(argv)
      arg_list = Notes.parse_argv(argv)
      options  = {
        :flags   => %w(TODO FIXME OPTIMIZE),
        :exclude => []
      }

      options[:dir] = arg_list.shift

      arg_list.reject(&:empty?).each do |set|
        flag, *args = set
        args.map! { |arg| arg.delete("/") } #{ }"log/" => "log"

        case flag
        when '-f', '--flags'   then options[:flags].concat(args)
        when '-e', '--exclude' then options[:exclude].concat(args)
        else puts "Unknown argument: #{flag}"
        end
      end

      @options = options
    end

    # List of files to scan for notes as specified in the options
    def files
      pattern = File.join(@options[:dir], "**/*")
      Dir[pattern].reject do |f|
        File.directory?(f) || @options[:exclude].any? { |dir| File.dirname(f).include?(dir) }
      end
    end

    # Read and parse all files as specified in the options
    def find_all
      Notes.files.each { |f| Notes.parse_file(f) }
    end

    # Scan a file for annotations and output numbered lines for each
    def parse_file(filename)
      name    = filename.gsub(Dir.pwd, '')
      counter = 1
      tasks   = []

      begin
        File.read(filename).each_line do |line|
          if @options[:flags].any? { |flag| line =~ /#{flag}/i }
            tasks << {
              :line_num => counter,
              :line     => line.strip
            }
          end
          counter += 1
        end
      rescue
        # Error occurred reading the file (ex. invalid byte sequence in UTF-8)
        # Move on quietly
      end

      if !tasks.empty?
        name.slice!(0) if name.start_with?("/")
        puts "#{name}:"

        tasks.each do |task|
          flag_regex = Regexp.new(@options[:flags].join('|'), true)
          color = 33 # yellow
          line  = task[:line].gsub(flag_regex) do |flag|
            "\e[#{color};1m#{flag}\033[0m"
          end
          puts "  ln #{task[:line_num]}: #{line}"
        end

        puts ""
      end
    end

  end

end

