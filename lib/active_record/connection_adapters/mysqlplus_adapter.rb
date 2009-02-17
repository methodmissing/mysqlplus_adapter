begin
  require_library_or_gem('mysqlplus')
rescue LoadError
  $stderr.puts <<-EOS
        The mysqlplus gem is required!
        'git clone git@github.com:oldmoe/mysqlplus.git && cd mysqlplus && rake'
        There's some experimental GC patches available @ http://github.com/oldmoe/mysqlplus/tree/with_async_validation - the mysql gem forces GC every 20 queries, that's a guaranteed GC cycle every 5th request for a request with a 4 query overhead.
      EOS
  exit
end

begin 
  require_library_or_gem('fastthread')
rescue LoadError
  $stderr.puts "'gem install fastthread' for better performance"
end  

[ "mysqlplus_adapter/connection_pool",
  "mysql_adapter",
  "mysqlplus_adapter/deferrable/result",
  "mysqlplus_adapter/deferrable/macro" ].each{|l| require "active_record/connection_adapters/#{l}" }

module ActiveRecord
  module ConnectionAdapters
    class MysqlplusAdapter < ActiveRecord::ConnectionAdapters::MysqlAdapter
      
      DEFERRABLE_SQL = /^(INSERT|UPDATE|ALTER|DROP|SELECT|DELETE|RENAME|REPLACE|TRUNCATE)/i.freeze

      # Accessor for the raw connection socket for integration with EventMachine etc.
      # 
      def socket
        @connection.socket
      end
      
      # Send a query in an async non-blocking manner
      #
      def send_query( sql, name = nil, skip_logging = false )
        if skip_logging
          @connection.send_query( sql )
        else  
          log("(Socket #{socket.to_s}, Thread #{Thread.current.object_id.to_s}) #{sql}",name) do 
            @connection.send_query( sql )
          end
        end
      end
      
      # Retrieve a #send_query result set
      #
      def get_result
        @connection.get_result
      end
      
      def execute(sql, name = nil, skip_logging = false) #:nodoc:
        if skip_logging
          @connection.c_async_query( sql )
        else  
          log("(Socket #{socket.to_s}, Thread #{Thread.current.object_id.to_s}) #{sql}",name) do 
            @connection.c_async_query( sql )
          end
        end  
      end
      
      # Determine if a given SQL snippet is deferrable to another Thread.
      #
      def deferrable?( sql )
        !open_transactions? && 
        initialized? && 
        deferrable_sql?( sql )
      end
      
      # Determine if the raw SQL can be deferred.This excludes changing users,
      # retrieving column information, per connection configuration etc.
      #
      def deferrable_sql?( sql )
        sql =~ DEFERRABLE_SQL
      end
      
      # Only support deferring connections once the framework has been initialized.
      #
      def initialized?
        Object.const_defined?( 'Rails' ) && ::Rails.initialized?
      end
      
      # Are there any open transactions ? 
      #
      def open_transactions?
        open_transactions != 0
      end

      private 

        def configure_connection #:nodoc:
          super 
          @connection.disable_gc = true if disable_gc? 
        end
      
        # See http://github.com/oldmoe/mysqlplus/tree/with_async_validation
        def disable_gc? #:nodoc:
          @connection.respond_to?( :disable_gc= )
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