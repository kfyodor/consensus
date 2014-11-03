# Consensus::Base.new 'localhost', 9001, 1

module Consensus
  # Celluloid.task_class = Celluloid::TaskThread

  class Base
    include Celluloid::IO

    def initialize(node_id, opts = {})
      @node_id = node_id
      @interval = opts[:interval] || 1
      @timeout  = opts[:timeout]  || 4

      init_actors

      parse_config
      start_server
    end

    def init_actors
      State.supervise_as :state, @node_id
      HealthChecker.supervise_as :health, @interval, @timeout
      Election.supervise_as :election
      MessageHandler.supervise_as :handler
    end

    def start
      Actor[:health].async.run
      Actor[:election].async.start

      run
    end    

    def run
      loop do
        handle_connection @server.accept
      end
    end

    def handle_connection(conn)
      _, port, host = conn.peeraddr

      async.listen_to(handshake(conn), conn)
    end

    def handshake(conn)
      wait_readable conn
      conn.readline.strip.to_i
    end

    def listen_to(node_id, conn)
      puts "#{node_id} is now connected to #{@node_id}"

      loop do
        begin
          wait_readable conn
          Actor[:handler].async.handle node_id, conn.readline.strip
        rescue EOFError
          puts "Node #{node_id} has been disconnented"
          conn.close

          Actor[:state].node(node_id).close_socket!

          break
        end
      end
    end

    def close
      @state.close
      @server.close if @server
    end

    private 

    def start_server
      @server = TCPServer.new(@host, @port)
    end

    def parse_config
      unless config["nodes"].keys.include?(@node_id)
        raise "There's no node with id=#{@node_id}" 
      end

      config["nodes"].each do |id, opts|
        Actor[:state] << Node.new(id, opts)
      end

      @host = Actor[:state].current_node.host.to_s
      @port = Actor[:state].current_node.port.to_i
    end

    def config
      @config ||= YAML.load(
        File.read File.expand_path 'config/nodes.yml'
      )
    end
  end
end