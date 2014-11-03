require 'yaml'

module Consensus
  class State
    include Celluloid

    attr_reader :leader

    def initialize(node_id)
      @node_id = node_id.freeze
      @nodes   = []
      @leader  = nil
    end

    def <<(node)
      @nodes << node
    end
    alias add_node <<

    def current_node
      @current_node ||= @nodes.select do |node|
        node.id == @node_id
      end.first
    end

    def older_nodes
      @nodes.select do |node|
        node.id > @node_id
      end
    end

    def broadcast(data)
      nodes.each do |n|
        n.async.notify!(current_node, data)
      end
    end

    def nodes
      @nodes.reject do |node|
        node.id == @node_id
      end
    end

    def node(node_id)
      @nodes.select { |n| n.id == node_id }.first
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

    def check_leader_health
      @leader.notify!(current_node, "PING")
    end

    def close
      @nodes.each do |n|
        n.socket.close if n.socket
      end 
    end
  end
end