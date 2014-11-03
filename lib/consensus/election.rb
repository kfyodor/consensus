module Consensus
  class Election
    include Celluloid
    include BaseActors

    def initialize(wait_timeout)
      @on_run           = false
      @election_counter = 0
      @response_counter = {}
      @wait_timeout     = wait_timeout
    end

    def inc_response_counter
      @response_counter[@election_counter] += 1
    end

    def on_run?
      @on_run
    end

    def start
      return if @on_run

      puts "Starting election."

      inc_election_counter
      reset_timer!

      @on_run = true

      state.set_leader nil

      if state.older_nodes.empty?
        set_new_leader
      else
        collect_responses
      end
    end

    def stop(new_leader)
      @on_run = false

      reset_timer!
      state.async.set_leader new_leader

      puts "Node #{new_leader.id} is the leader now"
    end

    private

    def set_new_leader
      state.async.broadcast "IMTHEKING"
      stop state.current_node
    end

    def collect_responses
      state.older_nodes.each do |node|
        node.async.notify! state.current_node, "ALIVE?"
      end

      @timer = after(@wait_timeout) do
        if response_counter && response_counter == 0
          set_new_leader
        end
      end
    end

    def reset_timer!
      @timer.cancel if @timer
    end

    def inc_election_counter
      @election_counter += 1
      @response_counter = { @election_counter => 0 }
    end

    def response_counter
      @response_counter[@election_counter]
    end
  end
end