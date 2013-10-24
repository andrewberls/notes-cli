module Notes
  class CLI
    def initialize
      # Hash with keys :locations, :flags, :exclude
      @options = Notes::Options.parse(ARGV)
    end

    # Scan a file for annotations and output numbered lines for each
    # TODO: this could use refactoring
    def parse_file(filename)
      flags      = @options[:flags]
      flag_regex = Regexp.new(flags.join('|'), true)
      name       = filename.gsub(Dir.pwd, '') # Relative file path
      tasks      = Notes::Tasks.for_file(File.expand_path(filename), flags)

      if !tasks.empty?
        name.slice!(0) if name.start_with?("/") # TODO - ?
        puts name + ':'
        tasks.each { |task| puts task.format(flag_regex) }
        puts ""
      end
    end

    # Read and parse all files as specified in the options
    # Only outputs to console; returns nothing
    def find_all
      files = Notes.valid_files(@options)
      flags = @options[:flags]
      flag_regex = Regexp.new(flags.join('|'), true)

      Notes::Tasks.for_files(files, flags).each do |filename, tasks|
        name = filename.gsub(Dir.pwd, '') # Print only relative paths
        name.slice!(0) if name.start_with?('/')
        puts name + ':'
        tasks.each { |task| puts task.format(flag_regex) }
        puts ''
      end
    end
  end
end

