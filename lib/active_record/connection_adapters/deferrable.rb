module ActiveRecord
  module Deferrable
    
    def self.included(base)
      base.extend( SingletonMethods )
    end
    
    module SingletonMethods
      def defer(*methods)
        methods.each do |method|
          class_eval <<-EOS
            def #{method}_with_defer(*args, &block)
              ActiveRecord::Deferrable::Result.new do
                #{method}_without_defer(*args, &block)
              end
            end

            alias_method_chain :#{method}, :defer
          EOS
        end
      end      
    end
    
    class Result < ActiveSupport::BasicObject

      def initialize( &query )
        @query = query
        defer!
        self
      end

      def defer!
        @result = Thread.new(@query) do |query|
          begin
            query.call    
          ensure
            ::ActiveRecord::Base.connection_pool.release_connection
          end    
        end
      end

      def method_missing(*args, &block)
        @_result ||= @result.value
        @_result.send(*args, &block)
      end 

    end    
  end  
end
=begin
module ActiveRecord
  class Base
    include ActiveRecord::Deferrable    
    
    class << self
      include ActiveRecord::Deferrable    
      defer :find_by_sql,
            #:exists?, # yields syntax err. with alias_method_chain
            :update_all,
            :delete_all,
            :count_by_sql,
            #:table_exists?, # yields syntax err. with alias_method_chain
            :columns,
            :select_all_rows,
            :select_limited_ids_list,
            :execute_simple_calculation,
            :execute_grouped_calculation
    end   
    
    defer :destroy,
          :update,
          :create,
          :update_with_lock            
    
  end
end

module ActiveRecord
  module Associations
    class HasAndBelongsToManyAssociation
      include ActiveRecord::Deferrable
      
      defer :insert_record,
            :delete_records
    end
  end
end
=end