# Internal options parser

module Notes
  module Options
    extend self

    DEFAULT_OPTIONS = {
      :flags     => %w(TODO FIXME OPTIMIZE),
      :exclude   => [],
      :files     => [],
      :directory => '',
    }

    FLAG_FLAGS    = ['-f', '--flags']
    EXCLUDE_FLAGS = ['-e', '--exclude']
    ALL_FLAGS     = FLAG_FLAGS + EXCLUDE_FLAGS

    def default_excludes
      if Notes.rails?
        %w(tmp log vendor)
      else
        []
      end
    end

    # Parse ARGV into a directory and list of argument groups
    # For example, given ['app/', -f', 'refactor', 'broken', '--exclude', 'tmp', 'log']:
    # => [ ['app/'], ['-f', 'refactor', 'broken'], ['--exclude', 'tmp', 'log'] ]
    #
    def arg_groups(args)
      result = []
      buf    = []

      # No dir was passed, use default
      if args.empty? || args.first.start_with?('-')
        result << [ Notes.root ]
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

    # Append received command line arguments to a default set of arguments
    # Returns Hash
    def parse(args)
      arg_list = arg_groups(args)
      options  = DEFAULT_OPTIONS.dup
      options[:exclude] += default_excludes
      options[:locations] = arg_list.shift

      arg_list.reject(&:empty?).each do |set|
        flag, *args = set
        args.map! { |arg| arg.delete("/") } # "log/" => "log"

        case flag
        when '-f', '--flags'   then options[:flags] += args
        when '-e', '--exclude' then options[:exclude] += args
        else puts "Unknown argument: #{flag}"
        end
      end

      options
    end

    # Return the default set of flags and locations
    def defaults
      parse({})
    end

  end
end
