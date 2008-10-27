module ActiveRecord
  module Deferrable
    module Macro
      
      class << self

        def install!
          ActiveRecord::Base.send :extend, SingletonMethods      
          ar_eigenclass::VALID_FIND_OPTIONS << :defer
          alias_deferred :find
          alias_deferred :find_by_sql
          alias_deferred :preload_associations
        end

        private

        def ar_eigenclass
          (class << ActiveRecord::Base; self; end)
        end

        def alias_deferred( method_signature ) 
          ar_eigenclass.alias_method_chain method_signature, :defer
        end

      end

    end

    module SingletonMethods

      def preload_associations_with_defer(records, associations, preload_options={})
        ActiveRecord::Deferrable::Result.new do
          preload_associations_without_defer(records, associations, preload_options={})
        end
      end

      def find_by_sql_with_defer( sql, defer = false )
        if defer
          ActiveRecord::Deferrable::Result.new do 
            find_by_sql_without_defer( sql )
          end
        else
          find_by_sql_without_defer( sql )
        end    
      end

      def find_with_defer( *args )
        options = args.dup.extract_options!
        if options[:defer]
          ActiveRecord::Deferrable::Result.new do 
            find_without_defer(*args)
          end
        else
          find_without_defer(*args)
        end    
      end  

    end

  end
end

ActiveRecord::Deferrable::Macro.install!