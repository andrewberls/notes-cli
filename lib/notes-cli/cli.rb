module Notes
  class CLI
    def initialize
      # Hash with keys :locations, :flags, :exclude
      @options = Notes::Options.parse(ARGV)
    end


    # Scan a file for annotations and output numbered lines for each
    def parse_file(filename)
      flags      = @options[:flags]
      tasks      = Notes::Tasks.for_file(File.expand_path(filename), flags)
      flag_regex = Regexp.new(flags.join('|'), true)
      name       = filename.gsub(Dir.pwd, '') # Relative file path

      if !tasks.empty?
        name.slice!(0) if name.start_with?("/") # TODO - ?
        puts name + ':'
        tasks.each { |task| puts task.format(flag_regex) }
        puts ""
      end
    end





    # files = Notes.valid_files(options)
    # flags = options[:flags]
    # Notes::Tasks.for_files(files, flags)
    #
    # =>
    #  {
    #    'app/assets/javascripts/test.js' => [<Notes::Task>, <Notes::Task>, ...]
    #    'app/assets/javascripts/something.js' => [<Notes::Task>, <Notes::Task>, ...]
    #  }


    def self.test
    end


    # Read and parse all files as specified in the options
    def find_all
    #   @options[:locations].each do |loc|
    #     if File.directory?(loc)
    #       Dir[ File.join(loc, "**/*") ].reject do |f|
    #         reject?(f)
    #       end.each { |f| parse_file(f) }
    #     else
    #       parse_file(loc)
    #     end
    #   end


      files = Notes.valid_files(@options)
      flags = @options[:flags]
      raise Notes::Tasks.for_files(files, flags).inspect
    end






  end
end

