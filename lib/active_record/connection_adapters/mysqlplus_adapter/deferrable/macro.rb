module ActiveRecord
  module Deferrable
    module Macro
      
      class << self

        def install!
          ActiveRecord::Base.send :extend, SingletonMethods      
          ar_eigenclass::VALID_FIND_OPTIONS << :defer
          alias_deferred :find, :find_by_sql, :preload_associations
        end

        private

          def ar_eigenclass #:nodoc:
            @@ar_eigneclass ||= (class << ActiveRecord::Base; self; end)
          end

          def alias_deferred( *method_signatures ) #:nodoc:
            method_signatures.each do |method_signature| 
              ar_eigenclass.alias_method_chain method_signature, :defer
            end
          end

      end

    end

    module SingletonMethods

      # !! EXPERIMENTAL !!
      # Since ActiveRecord 2.1, multiple lightweight queries is preferred to expensive
      # JOINS when eager loading related models.In some use cases it's more performant 
      # to distribute those over multiple connections versus dispatching them on the same
      # connection.
      # 
      # ....
      # Record.find(:first, :include => [:other. :another], :defer => true)
      # .... 
      #
      def preload_associations_with_defer(records, associations, preload_options={})
        if preload_options.key?(:defer)
          ActiveRecord::Deferrable::Result.new do
            preload_associations_without_defer(records, associations, preload_options)
          end
        else
          preload_associations_without_defer(records, associations, preload_options)
        end    
      end

      # Execute raw SQL in another Thread.Blocks only when the result is immediately
      # referenced.
      # ...
      # Record.find_by_sql( "SELECT SLEEP (1)", true ) 
      # ...
      #
      def find_by_sql_with_defer( sql, defer = false )
        if defer
          ActiveRecord::Deferrable::Result.new do 
            find_by_sql_without_defer( sql )
          end
        else
          find_by_sql_without_defer( sql )
        end    
      end

      # Executes a query in another background Thread.Blocks only when the result is
      # immediately referenced.
      # ...
      # Record.find( :first, :conditions => ['records.some_id >= ?', 100], :defer => true ) 
      # ...
      #
      def find_with_defer( *args )
        options = args.dup.extract_options!
        if options.key?(:defer)
          with_deferred_scope do
            ActiveRecord::Deferrable::Result.new do 
              find_without_defer(*args)
            end
          end  
        else
          find_without_defer(*args)
        end    
      end  

      private
      
        # Deferred finder scope
        #
        def with_deferred_scope( &block ) #:nodoc:
          with_scope( { :find => { :defer => true } }, :merge, &block )
        end

    end

  end
end

ActiveRecord::Deferrable::Macro.install!