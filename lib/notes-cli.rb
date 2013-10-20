require 'notes-cli/version'
require 'notes-cli/options'
require 'notes-cli/tasks'
require 'notes-cli/cli'


module Notes
  class << self

    # Determine if a file handle should be rejected based on type and
    # directories specified in options[:exclude]
    #
    # excluded - Array of directories to exclude from search
    # f - A String filename
    #
    # Return Boolean
    def is_directory_or_excluded?(excluded, f)
      is_in_excluded_dir = excluded.any? { |dir| File.dirname(f).include?(dir) }
      File.directory?(f) || is_in_excluded_dir
    end

    # Return an array of valid filenames for parsing
    #
    # options
    #   :locations - Array of files and directories to search
    #   :exclude   - Array of directories to exclude from search
    #
    # Return Array<String>
    def valid_files(options)
      locations = options[:locations]
      excluded  = options[:exclude]

      locations.flat_map do |loc|
        Dir[ File.join(loc, "**/*") ].reject do |f|
          is_directory_or_excluded?(excluded, f)
        end
      end
    end

  end
end
