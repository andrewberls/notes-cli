module Notes
  class CLI

    def initialize
      @options = Notes::Options.parse(ARGV)
    end

    # Read and parse all files as specified in the options
    # Prints filenames along with all tasks found per file
    # Only outputs to console; returns nothing
    def find_all
      files = Notes.valid_files(@options)

      Notes::Tasks.for_files(files, @options).each do |filename, tasks|
        # Print only relative paths, without leading ./
        name = filename.gsub(Dir.pwd, '')
        name.slice!(0..1) if name.start_with?('./')

        puts "#{name}:"
        tasks.each { |task| puts task.to_s }
        puts ''
      end
    end

  end
end

