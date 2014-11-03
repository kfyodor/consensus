module Consensus
  class MessageHandler
    include Celluloid

    def state;    Actor[:state];    end
    def election; Actor[:election]; end
    def health;   Actor[:health];   end

    def current_node
      state.current_node
    end

    def handle(node_id, data)
      from = state.node(node_id)

      puts "Node #{node_id} -> Node #{state.current_node.id}: #{data}"
      puts

      case data
      when "PING"
        from.async.notify!(current_node, "PONG")
      when "PONG"
        health.async.report(node_id)
      when "ALIVE?"
        from.async.notify!(current_node, "FINETHANKS")
        election.async.start
      when "FINETHANKS"
        election.async.inc_response_counter
      when "IMTHEKING"
        election.async.stop(from)
      end
    end
  end
end