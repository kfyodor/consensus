module Consensus
  class Node
    include Celluloid::IO
    include Comparable

    attr_reader :id, :host, :port, :socket

    def initialize(id, opts = {})
      @id      = id.to_i
      @host    = opts["host"].to_s
      @port    = opts["port"].to_i
    end

    def notify!(sender, data)
      open_socket(sender)

      if @socket
        wait_writable @socket
        @socket.puts data
      end
    rescue
    end

    def <=>(node)
      id <=> node.id
    end

    def close_socket!
      @socket.close if @socket
      @socket = nil
    end

    def open_socket(sender)
      @socket ||= begin
        TCPSocket.new(@host, @port).tap do |s|
          wait_writable s
          s.puts sender.id
        end 
      rescue => e
      end
    end
  end
end