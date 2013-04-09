
module Notes
  class CLI
    attr_accessor :options

    def initialize
      @options = Opts.parse(ARGV)
    end

    # Print a formatted task, with highlighting
    def print_task(task)
      flag_regex = Regexp.new(@options[:flags].join('|'), true)
      color = 33 # yellow
      line  = task[:line].gsub(flag_regex) do |flag|
        "\e[#{color};1m#{flag}\033[0m"
      end

      puts "  ln #{task[:line_num]}: #{line}"
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
        tasks.each { |t| print_task(t) }
        puts ""
      end
    end

    # Read and parse all files as specified in the options
    def find_all
      @options[:locations].each do |loc|
        if File.directory?(loc)
          Dir[ File.join(loc, "**/*") ].reject do |f|
            File.directory?(f) || @options[:exclude].any? { |dir| File.dirname(f).include?(dir) }
          end.each { |f| parse_file(f) }
        else
          parse_file(loc)
        end
      end
    end

  end
end

