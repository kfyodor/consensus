# Consensus::Base.new 'localhost', 9001, 1

module Consensus
  # Celluloid.task_class = Celluloid::TaskThread

  class Base
    include Celluloid::IO

    def initialize(node_id, opts = {})
      @node_id          = node_id
      @timeout          = opts[:timeout] || 1
      @state            = State.new(@node_id)
      @ticks_count      = 0
      @election_counter = 0
      @response_counter = {}
      @health_response  = {}

      parse_config
      start_server
    end

    def start
      trap(:INT) { close }

      tick

      start_election!

      run
    end    

    def tick
      n = 4

      every(@timeout) do
        @ticks_count += 1

        if !@state.election? && !@state.current_node_is_leader?
          @state.check_leader_health

          if @ticks_count >= n && @health_response.values_at(*((@ticks_count - n)..(@ticks_count - 1)).to_a).compact.any?
            @health_response.delete(@ticks_count - n) # we don't want this to grow
          else
            puts "Node #{@state.current_node.id} has't heard from the leader for a while..."
            start_election!
          end
        end
      end
    end

    def run
      loop do
        handle_connection @server.accept
      end
    end

    def handle_connection(conn)
      _, port, host = conn.peeraddr

      wait_readable conn

      node_id = conn.readline.strip.to_i

      puts "#{node_id} is now connected to #{@node_id}"

      async.listen_to(node_id, conn)
    end

    def listen_to(node_id, conn)
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

      if @state.leader
        puts "Leader is Node #{@state.leader.id}"
      end

      puts "Node #{node_id} -> Node #{@node_id}: #{data}"
      puts

      case data
      when "PING"
        from.notify!(@state.current_node, "PONG")
      when "PONG"
        @health_response[@ticks_count] = true
      when "ALIVE?"
        from.notify!(@state.current_node, "FINETHANKS")
        start_election!
      when "FINETHANKS"
        @response_counter[@election_counter]  += 1
      when "IMTHEKING"
        stop_election!(from)
      end
    end

    def start_election!
      puts "Starting election."

      @state.leader = nil

      @election_counter += 1
      @response_counter[@election_counter] = 0

      older_nodes = @state.older_nodes

      if older_nodes.empty?
        @state.broadcast("IMTHEKING")
        stop_election!(@state.current_node)
      else
        older_nodes.each do |node|
          node.notify! @state.current_node, "ALIVE?"
        end

        after(@timeout) do
          if @response_counter[@election_counter] == 0
            @state.broadcast("IMTHEKING")
            stop_election!(@state.current_node)
          end
        end
      end
    end

    def stop_election!(new_leader)
      puts "Leader is set to Node #{new_leader.id}"
      @state.leader = new_leader
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