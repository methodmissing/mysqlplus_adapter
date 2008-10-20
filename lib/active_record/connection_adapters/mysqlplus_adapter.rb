begin
  require_library_or_gem('mysqlplus')
rescue LoadError
  $stderr.puts '!!! The mysqlplus gem is required!'
  raise
end
require 'active_record/connection_adapters/mysql_adapter'
require 'active_record/connection_adapters/deferrable'

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
        warmup! if spec.config[:warmup]
      end

      def checkout_existing_connection
        existing = existing_connections()
        c = existing.detect{|c| c.idle? } || existing.first
        checkout_and_verify(c)
      end

      def existing_connections
        @connections - @checked_out
      end  

      private
      
        def warmup!
          @connection_mutex.synchronize do
            1.upto(@size) do
              c = new_connection
              @connections << c
            end
          end  
        end  

    end  
  end    
end    

ActiveRecord::ConnectionAdapters::MysqlAdapter.class_eval do
  def idle?
    true
  end
end

module ActiveRecord
  module ConnectionAdapters
    class MysqlplusAdapter < ActiveRecord::ConnectionAdapters::MysqlAdapter
      
      DEFERRABLE_SQL = /^(INSERT|UPDATE|ALTER|DROP|SELECT|DELETE|RENAME|REPLACE|TRUNCATE)/i

      def socket
        @connection.socket
      end
      
      def idle?
        @connection.idle?
      end
      
      def execute(sql, name = nil) #:nodoc:
        log("(Socket #{socket.to_s}) #{sql}",name) do 
          if deferrable?( sql )
            ::ActiveRecord::Deferrable::Result.new( sql, @connection.query_with_result )  
          else
            @connection.c_async_query( sql )
          end
        end
      end
      
      def deferrable?( sql )
        !open_transactions? && initialized? && deferrable_sql?( sql )
      end
      
      def deferrable_sql?( sql )
        sql =~ DEFERRABLE_SQL
      end
      
      def initialized?
        Object.const_defined?( 'Rails' ) && ::Rails.initialized?
      end
      
      def open_transactions?
        open_transactions != 0
      end

      private 

      def configure_connection
        super 
        @connection.disable_gc = true
      end
 
    end
  end
end

module ActiveRecord
  class << Base
    
    def mysqlplus_connection(config)
      config = config.symbolize_keys
      host     = config[:host]
      port     = config[:port]
      socket   = config[:socket]
      username = config[:username] ? config[:username].to_s : 'root'
      password = config[:password].to_s

      if config.has_key?(:database)
        database = config[:database]
      else
        raise ArgumentError, "No database specified. Missing argument: database."
      end      
          
      mysql = Mysql.init
      mysql.ssl_set(config[:sslkey], config[:sslcert], config[:sslca], config[:sslcapath], config[:sslcipher]) if config[:sslca] || config[:sslkey]

      ConnectionAdapters::MysqlplusAdapter.new(mysql, logger, [host, username, password, database, port, socket], config)    
    end
    
  end
end    