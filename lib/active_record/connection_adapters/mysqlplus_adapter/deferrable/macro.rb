module ActiveRecord
  module Deferrable
    module Macro
      
      class << self

        def install!
          ActiveRecord::Base.send :extend, SingletonMethods      
          ar_eigenclass::VALID_FIND_OPTIONS << :defer
          ar_eigenclass.alias_method_chain :find, :defer
        end

        private

        def ar_eigenclass
          (class << ActiveRecord::Base; self; end)
        end

      end

    end

    module SingletonMethods

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