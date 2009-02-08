module ActiveRecord
  module Deferrable
    class Result < ActiveSupport::BasicObject
       
      # Represents a Lazy Loaded resultset.
      # Any method calls would block if the result hasn't yet been processed in a background
      # Thread. 
      #
      def initialize( &deferrable )
        defer!( deferrable )
      end

      # Calls a given procedure in a background Thread, on another
      # connection from the pool.Guarantees that said connection is checked
      # back in on completion.
      #
      def defer!( deferrable )
        @result = Thread.new( deferrable ) do |deferrable|
          puts '*'
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
      
      # Delegates to the background Thread.
      #
      def method_missing(*args, &block)
        @_result ||= @result.value
        validate!
        @_result.send(*args, &block)
      end 
      
      # Re-raise any Exceptions from the background Thread.
      #
      def validate!
        raise @_result if @_result.is_a?( Exception )
      end

    end    
  end
end  