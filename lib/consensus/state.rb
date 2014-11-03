require 'yaml'

module Consensus
  class State
    include Celluloid
    include BaseActors

    attr_reader :leader, :current_node

    def initialize(node_id)
      @node_id      = node_id.freeze
      @nodes        = {}
      @leader       = nil
      @current_node = nil
    end

    def <<(node)
      if node.id == @node_id
        @current_node = node
      else
        @nodes[node.id] = node
      end
    end
    alias add_node <<

    def open_connections!
      nodes.each {|n| n.open_socket(current_node) }
    end

    def older_nodes
      nodes.select do |node|
        node.id > @node_id
      end
    end

    def broadcast(data)
      nodes.each do |n|
        n.async.notify!(current_node, data)
      end
    end

    def node(node_id)
      @nodes[node_id]
    end

    def nodes
      @nodes.values
    end

    def all_nodes
      nodes + [current_node]
    end

    def set_leader(leader)
      @leader = leader
    end

    def election?
      Celluloid::Actor[:election].on_run?
    end

    def current_node_is_leader?
      @leader && (@leader.id == current_node.id)
    end

    def check_health?
      @leader && (current_node.id != @leader.id) && !election?
    end

    def check_leader_health
      @leader && @leader.notify!(current_node, "PING")
    end

    def close
      all_nodes.each do |n|
        n.socket.close if n.socket
      end 
    end
  end
end