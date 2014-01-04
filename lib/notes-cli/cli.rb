module Notes
  class CLI

    def initialize(argv)
      @options = Notes::Options.parse(argv)
    end

    # Read and parse all files as specified in the options
    # Prints filenames along with all tasks found per file
    # Only outputs to console; returns nothing
    def find_all
      task_map = Notes::Tasks.all(@options).group_by(&:filename)

      task_map.each do |filename, tasks|
        puts "#{filename}:"
        tasks.each { |task| puts '  ' + task.to_s }
        puts ''
      end
    end

  end
end

