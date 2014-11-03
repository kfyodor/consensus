module Consensus

  class Base
    include Celluloid::IO
    include BaseActors

    def initialize(node_id, opts = {})
      @node_id  = node_id
      @interval = opts[:interval] || 1
      @timeout  = opts[:timeout]  || 4

      init_actors

      parse_config
      start_server
    end

    def init_actors
      State.supervise_as          :state,    @node_id
      HealthChecker.supervise_as  :health,   @interval, @timeout
      Election.supervise_as       :election, @interval
      MessageHandler.supervise_as :handler
    end

    def run
      state.async.open_connections!
      health.async.run
      election.async.start

      loop { async.handle_connection @server.accept }
    end

    def handle_connection(conn)
      _, port, host = conn.peeraddr
      async.listen_to(conn)
    end

    def listen_to(conn)
      wait_readable conn
      node_id = conn.readline.strip.to_i

      puts "#{node_id} is now connected to #{@node_id}"

      loop do
        begin
          wait_readable conn
          handler.async.handle(node_id, conn.readline)
        rescue EOFError
          puts "Node #{node_id} has been disconnented"

          conn.close
          state.node(node_id).close_socket!

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
        state << Node.new(id, opts)
      end

      @host = state.current_node.host.to_s
      @port = state.current_node.port.to_i
    end

    def config
      @config ||= YAML.load(File.read File.expand_path 'config/nodes.yml')
    end
  end
end