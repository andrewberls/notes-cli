module Notes
  class CLI
    def initialize
      # Hash with keys :locations, :flags, :exclude
      @options = Notes::Options.parse(ARGV)
    end


    # Scan a file for annotations and output numbered lines for each
    def parse_file(filename)
      tasks      = Notes::Tasks.for_file(File.expand_path(filename), @options)
      flag_regex = Regexp.new(@options[:flags].join('|'), true)
      name       = filename.gsub(Dir.pwd, '')

      if !tasks.empty?
        name.slice!(0) if name.start_with?("/") # TODO - ?
        puts name + ':'
        tasks.each { |task| puts task.format(flag_regex) }
        puts ""
      end
    end

    # Determine if a file handle should be rejected based on type and
    # directories specified in options[:exclude]
    def reject?(f)
      is_excluded_dir = @options[:exclude].any? { |dir| File.dirname(f).include?(dir) }
      File.directory?(f) || is_excluded_dir
    end

    # Read and parse all files as specified in the options
    def find_all
      @options[:locations].each do |loc|
        if File.directory?(loc)
          Dir[ File.join(loc, "**/*") ].reject do |f|
            reject?(f)
          end.each { |f| parse_file(f) }
        else
          parse_file(loc)
        end
      end
    end

  end
end

