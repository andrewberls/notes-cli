module Notes
  class CLI

    def initialize
      @options = Notes::Options.parse(ARGV)
    end

    # Read and parse all files as specified in the options
    # Prints filenames along with all tasks found per file
    # Only outputs to console; returns nothing
    def find_all
      files    = Notes.valid_files(@options)
      task_map = Notes::Tasks.for_files(files, @options).group_by(&:filename)

      task_map.each do |filename, tasks|
        puts "#{filename}:"
        tasks.each { |task| puts task.to_s }
        puts ''
      end
    end

  end
end

