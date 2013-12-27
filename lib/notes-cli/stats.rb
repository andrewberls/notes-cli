module Notes
  module Stats
    extend self

    # Take in a set of tasks and compute aggregate stats such as counts per
    # flag. Intended to augment a JSON set
    #
    # all_tasks: Hash of { filename -> [tasks] }
    #
    # Returns Hash
    def compute(all_tasks)
      totals = Hash.new(0)

      all_tasks.each do |filename, tasks|
        tasks.each do |task|
          task.flags.each { |flag| totals[flag] += 1 }
        end
      end

      { totals: totals }
    end

  end
end
