module ActiveRecord
  module Deferrable
    module Macro
      
      class << self

        def install!
          ActiveRecord::Base.send :extend, SingletonMethods      
          ar_eigenclass::VALID_FIND_OPTIONS << :defer
          alias_deferred :find, :find_by_sql, :preload_associations, :find_every
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
      # Record.find(:first, :include => [:other, :another], :defer => true)
      # .... 
      #
      def preload_associations_with_defer(records, associations, preload_options={})
        if preload_deferred?( associations )        
          associations.delete(:defer)
          records = [records].flatten.compact.uniq
          return if records.empty?
          case associations
          when Array then associations.each {|association| ActiveRecord::Deferrable::Result.new{ preload_associations_without_defer(records, association, preload_options) } }
          when Symbol, String then ActiveRecord::Deferrable::Result.new{ preload_one_association(records, associations.to_sym, preload_options) }
          when Hash then
            associations.each do |parent, child|
              raise "parent must be an association name" unless parent.is_a?(String) || parent.is_a?(Symbol)
              preload_associations(records, parent, preload_options)
              reflection = reflections[parent]
              parents = records.map {|record| record.send(reflection.name)}.flatten.compact
              unless parents.empty?
                parents.first.class.preload_associations(parents, child)
              end
            end
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

        def find_every_with_defer(options) #:nodoc:
          include_associations = merge_includes(scope(:find, :include), options[:include])
          if include_associations.any? && references_eager_loaded_tables?(options)
            records = find_with_associations(options)
          else
            records = find_by_sql(construct_finder_sql(options))
            if include_associations.any?
              preload_associations(records, preload_deferred_includes( include_associations, options ))
            end
          end

          records.each { |record| record.readonly! } if options[:readonly]

          records
        end

        def preload_deferred_includes( include_associations, options ) #:nodoc:
          options[:defer] ? (Array(include_associations) << :defer) : include_associations
        end

        def preload_deferred?( associations ) #:nodoc:
          begin
            associations.respond_to?(:include?) && associations.include?(:defer)
          rescue TypeError
            #failing test cases :
            # * test_eager_with_valid_association_as_string_not_symbol(EagerAssociationTest) && 
            # * test_eager_with_invalid_association_reference(EagerAssociationTest)            
            false
          end
        end

    end

  end
end

ActiveRecord::Deferrable::Macro.install!