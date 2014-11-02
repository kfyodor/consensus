module Consensus
  require 'consensus/log'

  class Node
    attr_reader :id, :host, :port

    # state_machine

    def initialize(id, cluster, opts = {})
      @id      = id.to_i
      @cluster = cluster
      @log     = Log.new
    end

    def start_election
    end

    def leader?
      id == @cluster.leader.id
    end

    def follower?
      !leader?
    end
  end
end