# Consensus::Base.new 'localhost', 9001, 1

module Consensus
  # Celluloid.task_class = Celluloid::TaskThread

  class Base
    include Celluloid::IO

    def initialize(node_id, opts = {})
      @node_id = node_id
      @interval = opts[:interval] || 1
      @timeout  = opts[:timeout]  || 4

      State.supervise_as :state, @node_id
      @state = Celluloid::Actor[:state]

      HealthChecker.supervise_as :health, @interval, @timeout
      @health_checker = Celluloid::Actor[:health]

      Election.supervise_as :election
      @election = Celluloid::Actor[:election]


      parse_config
      start_server
    end

    def start
      @health_checker.async.run
      @election.async.start
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
          handle_message_from node_id, conn.readline.strip
        rescue EOFError
          puts "Node #{node_id} has been disconnented"
          conn.close
          @state.node(node_id).close_socket!

          break
        end
      end
    end

    def handle_message_from(node_id, data)
      from = @state.node(node_id)

      puts "Node #{node_id} -> Node #{@node_id}: #{data}"
      puts

      case data
      when "PING"
        from.async.notify!(@state.current_node, "PONG")
      when "PONG"
        @health_checker.async.report(node_id)
      when "ALIVE?"
        from.async.notify!(@state.current_node, "FINETHANKS")
        @election.async.start
      when "FINETHANKS"
        @election.async.inc_response_counter
      when "IMTHEKING"
        @election.async.stop(from)
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
        @state << Node.new(id, opts)
      end

      @host = @state.current_node.host.to_s
      @port = @state.current_node.port.to_i
    end

    def config
      @config ||= YAML.load(
        File.read File.expand_path 'config/nodes.yml'
      )
    end
  end
end