module Consensus
  class Election
    include Celluloid
    include BaseActors

    def initialize
      @on_run = false
      @election_counter = 0
      @response_counter = {}
    end

    def inc_response_counter
      @response_counter[@election_counter] += 1
    end

    def inc_election_counter
      @election_counter += 1
      @response_counter = { @election_counter => 0 }
    end

    def response_counter
      @response_counter[@election_counter]
    end

    def on_run?
      @on_run
    end

    def start
      puts "Starting election."

      inc_election_counter

      @on_run = true

      state.set_leader nil

      older_nodes = state.older_nodes

      if older_nodes.empty?
        state.async.broadcast "IMTHEKING"
        stop state.current_node
      else
        older_nodes.each do |node|
          node.notify! state.current_node, "ALIVE?"
        end

        after(1) do
          if response_counter && response_counter == 0
            state.async.broadcast "IMTHEKING"

            stop state.current_node
          end
        end
      end
    end

    def stop(new_leader)
      @on_run = false

      puts "Leader is set to Node #{new_leader.id}"
      state.async.set_leader new_leader
    end
  end
end