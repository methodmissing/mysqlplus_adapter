module ActiveRecord
  module Deferrable
    class Result < ActiveSupport::BasicObject

      def initialize( &deferrable )
        defer!( deferrable )
      end

      def defer!( deferrable )
        @result = Thread.new( deferrable ) do |deferrable|
          begin
            deferrable.call 
          rescue => exception
            exception  
          ensure
            ::ActiveRecord::Base.connection_pool.release_connection            
          end
        end
        self
      end
      
      def method_missing(*args, &block)
        @_result ||= @result.value
        validate!
        @_result.send(*args, &block)
      end 
      
      def validate!
        raise @_result if @_result.is_a?( Exception )
      end

    end    
  end
end  