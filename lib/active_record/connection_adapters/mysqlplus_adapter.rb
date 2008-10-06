begin
  require_library_or_gem('mysqlplus')
rescue LoadError
  $stderr.puts '!!! The mysqlplus gem is required!'
  raise
end
require 'active_record/connection_adapters/mysql_adapter'
#require 'active_record/connection_adapters/deferrable'

module ActiveRecord
  module ConnectionAdapters
    class ConnectionPool
      attr_reader :connections, 
                  :checked_out
      
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

module ActiveRecord
  module ConnectionAdapters
    class MysqlplusAdapter < ActiveRecord::ConnectionAdapters::MysqlAdapter

      def socket
        @connection.socket
      end
      
      def execute(sql, name = nil) #:nodoc:
        log("(Socket #{socket.to_s}) #{sql}",name) do 
          @connection.c_async_query( sql )
        end
      end
 
      def insert_sql(sql, name = nil, pk = nil, id_value = nil, sequence_name = nil) #:nodoc:
        without_result do
          super sql, name
        end  
        id_value || @connection.insert_id
      end

      def update_sql(sql, name = nil) #:nodoc:
        without_result do
          super
        end  
        @connection.affected_rows
      end  

      def begin_db_transaction #:nodoc:
        without_result do
          execute "BEGIN"
        end
      rescue Exception
        # Transactions aren't supported
      end

      def commit_db_transaction #:nodoc:
        without_result do
          execute "COMMIT"
        end
      rescue Exception
        # Transactions aren't supported
      end

      def rollback_db_transaction #:nodoc:
        without_result do
          execute "ROLLBACK"
        end
      rescue Exception
        # Transactions aren't supported
      end

      private 

      def without_result
        begin
          @connection.query_with_result = false
          yield
        ensure
          @connection.query_with_result = true
        end
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