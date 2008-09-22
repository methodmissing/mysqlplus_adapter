begin
  require_library_or_gem('mysqlplus')
rescue LoadError
  $stderr.puts '!!! The mysqlplus gem is required!'
  raise
end
require 'active_record/connection_adapters/mysql_adapter'

module ActiveRecord
  module ConnectionAdapters
    class MysqlplusAdapter < ActiveRecord::ConnectionAdapters::MysqlAdapter
      
      def adapter_name
        'Mysqlplus'
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