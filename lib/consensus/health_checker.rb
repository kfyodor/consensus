module Consensus
  class HealthChecker
    include BaseActors
    include Celluloid

    class HealthReport
      def initialize(timeout)
        @timeout  = timeout

        reset!
      end

      def report!(data)
        @report[@ticks_count] = data
      end

      def reset!
        @ticks_count   = 0
        @report = {}
      end

      def inc!
        @ticks_count += 1
        cleanup_old_keys!
      end

      def leader_respond?(node_id)
        backlog.select { |id| id == node_id }.compact.any?
      end

      def has_backlog?
        backlog.size >= @timeout
    end

      def backlog
        @report.values_at(*(range_start..range_end).to_a)
      end

      private

      def old_keys
        @report.keys.select { |k| k < range_start }
      end

      def cleanup_old_keys!
        old_keys.any? && old_keys.each do |key|
          @report.delete key
        end
      end

      def range_start
        if @ticks_count - @timeout > 0
          @ticks_count - @timeout
        else
          1
        end
      end

      def range_end
        @ticks_count
      end
    end

    def initialize(interval, timeout)
      @interval      = interval
      @health_report = HealthReport.new(timeout)
    end

    def reset_ticks_counter!
      @health_report.reset!
    end

    def report(node_id)
      @health_report.report!(node_id)
    end

    def run
      every @interval do
        @health_report.inc!
        check_health
      end
    end

    def check_health
      if state.check_health?
        state.async.check_leader_health
        check_leader_response
      end
    end

    def check_leader_response
      return unless @health_report.has_backlog?

      unless @health_report.leader_respond?(state.leader.id)
        puts "Node #{state.current_node.id} has't heard from the leader for a while..."
        election.async.start
      end
    end
  end
end