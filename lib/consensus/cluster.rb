module Consensus
  class Cluster
    attr_reader :leader

    def initialize(nodes = [])
      @nodes  = nodes
      @leader = nil
    end

    def candidates_for(node_id)
    end
  end
end