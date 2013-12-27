require 'set'

module Notes
  module Stats
    extend self

    def compute(tasks)
      {
        flag_counts: flag_counts(tasks),
        distinct_flags: distinct_flags(tasks)
      }
    end

    # Take in a set of tasks and compute aggregate stats such as counts per
    # flag. Intended to augment a JSON set
    #
    # task_map: Hash of { filename -> [tasks] }
    #
    # Returns Hash
    def flag_counts(task_map)
      counts = Hash.new(0)

      task_map.each do |filename, tasks|
        tasks.each do |task|
          task.flags.each { |flag| counts[flag] += 1 }
        end
      end

      { flag_counts: counts }
    end

    # Compute the distinct flags found in a a set of tasks
    #
    # task_map: Hash of { filename -> [tasks] }
    #
    # Returns Array[String] of flag names
    def distinct_flags(task_map)
      flags = Set.new
      task_map.each do |filename, tasks|
        tasks.each { |task| flags.merge(task.flags) }
      end
      flags.to_a
    end

  end
end
