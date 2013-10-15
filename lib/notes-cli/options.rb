module Notes
  module Options

    DEFAULT_OPTIONS = {
      :flags     => %w(TODO FIXME OPTIMIZE),
      :exclude   => [],
      :files     => [],
      :directory => '',
    }

    FLAG_FLAGS    = ['-f', '--flags']
    EXCLUDE_FLAGS = ['-e', '--exclude']
    ALL_FLAGS     = FLAG_FLAGS + EXCLUDE_FLAGS

    # Parse ARGV into a directory and list of argument groups
    # For example, given ['app/', -f', 'refactor', 'broken', '--exclude', 'tmp', 'log']:
    # => [ ['app/'], ['-f', 'refactor', 'broken'], ['--exclude', 'tmp', 'log'] ]
    #
    def self.arg_groups(args)
      result = []
      buf    = []

      # No dir was passed, use current dir
      if args.empty? || args.first.start_with?('-')
        result << [ Dir.pwd ]
      end

      args.each do |arg|
        if ALL_FLAGS.include?(arg)
          result << buf unless buf.empty?
          buf = []
        end
        buf << arg
      end

      result << buf
    end

    # Append any command line arguments to a default set of arguments
    def self.parse(args)
      arg_list = arg_groups(args)
      options  = DEFAULT_OPTIONS

      options[:locations] = arg_list.shift

      arg_list.reject(&:empty?).each do |set|
        flag, *args = set
        args.map! { |arg| arg.delete("/") } # "log/" => "log"

        case flag
        when '-f', '--flags'   then options[:flags].concat(args)
        when '-e', '--exclude' then options[:exclude].concat(args)
        else puts "Unknown argument: #{flag}"
        end
      end

      options
    end

  end
end
