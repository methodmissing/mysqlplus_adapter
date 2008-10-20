module ActiveRecord
  module Deferrable
    class Result < ActiveSupport::BasicObject

      def initialize( sql, query_with_result )
        @sql, @query_with_result = sql, query_with_result
        defer!
      end

      def defer!
        @result = Thread.new(@sql, @query_with_result) do |sql,query_with_result|
          begin
            ::ActiveRecord::Base.connection_pool.with_connection do |conn|
              puts "Socket: #{conn.socket.inspect}, Thread: #{Thread.current.object_id}, Connection: #{::ActiveRecord::Base.connection_pool.send(:current_connection_id)}, Main: #{Thread.main.object_id}"
              conn.raw_connection.query_with_result = query_with_result
              conn.raw_connection.c_async_query( sql )
            end
          rescue => exception
            exception  
          end  
        end
        self
      end
      
      def method_missing(*args, &block)
        @_result ||= @result.value
        raise @_result if @_result.is_a?( Exception )
        @_result.send(*args, &block)
      end 

    end    
  end  
end