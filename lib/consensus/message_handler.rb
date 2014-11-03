module Consensus
  class MessageHandler
    include BaseActors
    include Celluloid

    def current_node
      state.current_node
    end

    def handle(node_id, data)
      puts "Node #{node_id} -> Node #{state.current_node.id}: #{data}"
      puts

      from = state.node(node_id)

      case data.strip
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