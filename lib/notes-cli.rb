module Notes
  extend self

  # The root directory in which we're searching
  def root
    rails? ? Rails.root : Dir.pwd
  end

  # Are we being included into a Rails project?
  def rails?
    !!defined?(Rails)
  end

  # Are we in a git repo?
  def git?
    Dir.chdir(root) do
      `git status 2>/dev/null`
      return $?.success?
    end
  end

  # Parse raw output from git-blame(1)
  # (results not interpreted except for SHA)
  #
  # Returns Hash
  def blame(filename, line_num)
    fields = {}

    begin
      Dir.chdir(root) do
        blame = `git blame -L#{line_num},#{line_num} --line-porcelain -- #{filename} 2>/dev/null`.split("\n")
        sha = blame.shift.split(' ').first
        fields['sha'] = sha if sha != '0'*40 # Only use actual commit SHAs

        blame.each do |line|
          fieldname, *values = line.split(' ')
          fields[fieldname]  = values.join(' ')
        end
      end
    rescue
    end

    fields
  end

  COLORS = {
    'yellow' => 33
  }

  def colorize(color, str)
    "\e[#{COLORS[color]};1m#{str}\033[0m"
  end

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
      if File.directory?(loc)
        Dir[ File.join(loc, "**/*") ]
          .reject do |f| is_directory_or_excluded?(excluded, f) end
      else
        loc
      end
    end
  end

end

require 'notes-cli/version'
require 'notes-cli/options'
require 'notes-cli/tasks'
require 'notes-cli/stats'
require 'notes-cli/cli'
