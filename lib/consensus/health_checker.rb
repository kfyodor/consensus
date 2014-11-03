module Consensus

  # checks current leader's health

  class HealthChecker
    include Celluloid

    def initialize(interval, timeout)
      @timeout     = timeout
      @interval    = interval
      @ticks_count = 0

      @health_response  = {}
    end

    def state
      Celluloid::Actor[:state]
    end

    def election
      Celluloid::Actor[:election]
    end

    def report(node_id)
      @health_response[@ticks_count] = node_id
    end

    def run
      every @interval do
        @ticks_count += 1
        check_health
      end
    end

    def check_health
      if !state.election? && !state.current_node_is_leader?
        state.async.check_leader_health

        ### HERE's A NASTY BUG
        if @ticks_count >= @timeout && @health_response.values_at(*((@ticks_count - @timeout)..(@ticks_count - 1)).to_a).compact.any?
          @health_response.delete(@ticks_count - @timeout) # we don't want this to grow
        else
          puts "Node #{state.current_node.id} has't heard from the leader for a while..."
          election.async.start
        end
      end
    end
  end
end