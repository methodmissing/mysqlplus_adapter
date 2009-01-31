module ActiveRecord
  module ConnectionAdapters
    class ConnectionPool
      
      attr_reader :connections, 
                  :checked_out,
                  :reserved_connections

      def initialize(spec)
        @spec = spec
        # The cache of reserved connections mapped to threads
        @reserved_connections = {}
        # The mutex used to synchronize pool access
        @connection_mutex = Monitor.new
        @queue = @connection_mutex.new_cond
        # default 5 second timeout
        @timeout = spec.config[:wait_timeout] || 5
        # default max pool size to 5
        @size = (spec.config[:pool] && spec.config[:pool].to_i) || 5
        @connections = []
        @checked_out = []
        # warmup hook
        warmup! if spec.config[:warmup]
      end

      private
      
        # Establish ( warmup ) all connections for this pool in advance.
        #
        def warmup!
          @connection_mutex.synchronize do
            1.upto(@size) do
              @connections << new_connection
            end
          end  
        end  

    end  
  end    
end