begin
  require_library_or_gem('mysqlplus')
rescue LoadError
  $stderr.puts '!!! The mysqlplus gem is required!'
  raise
end
require 'active_record/connection_adapters/mysql_adapter'

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
        warmup!
      end
      
      alias :original_checkout_existing_connection :checkout_existing_connection
      
      def checkout_existing_connection
        c = (@connections - @checked_out).detect{|c| c.ready? }
        checkout_and_verify(c)
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
  class Base

    class << self

      def find_by_sql(sql)
        connection_pool.with_connection do |connection|
          connection.select_all(sanitize_sql(sql), "#{name} Load").collect! { |record|   instantiate(record) }
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

      def ready?
        @connection.ready?        
      end
      
      def execute(sql, name = nil) #:nodoc:
        log(sql,name) do 
          @connection.c_async_query(sql)
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