module Consensus
  class Log
    class Entry
      def initialize(id, data)
        @id   = id
        @data = data
      end
    end

    def initialize
      @entries = []
    end

    def <<(entry)
      @entries << Entry.new
    end
  end
end