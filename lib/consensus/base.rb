require 'celluloid/io'

module Consensus
  class Base
    include Celluloid::IO

    def initialize(host, port, node_id, opts = {})
      @cluster = Cluster.new
      @node    = Node.new node_id, @cluster
      @server  = TCPServer.new(host, port)
      @timeout = opts[:timeout] || 1
    end

    def run
      every(TIMEOUT) do
        puts "hey!"
      end

      loop do
        async.handle @server.accept
      end
    end

    def handle(data)
      puts data
    end

    def close
      @server.close if @server
    end
  end
end