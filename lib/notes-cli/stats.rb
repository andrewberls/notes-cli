require 'set'

module Notes
  module Stats
    extend self

    def compute(tasks)
      {
        flag_counts: flag_counts(tasks),
        found_flags: found_flags(tasks)
      }
    end

    # Take in a set of tasks and compute aggregate stats such as counts per
    # flag. Intended to augment a JSON set
    #
    # tasks: Array[Notes::Task]
    #
    # Returns Hash
    def flag_counts(tasks)
      counts = Hash.new(0)
      tasks.each do |task|
        task.flags.each { |flag| counts[flag] += 1 }
      end
      counts
    end

    # Compute the distinct flags found in a a set of tasks
    #
    # tasks: Array[Notes::Task]
    #
    # Returns Array[String] of flag names
    def found_flags(tasks)
      flags = Set.new
      tasks.each { |task| flags.merge(task.flags) }
      flags.to_a
    end

  end
end
