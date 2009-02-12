require "#{File.dirname(__FILE__)}/helper"

Mysqlplus::Test.prepare!

class ConnectionPoolTest < ActiveSupport::TestCase
  
  def teardown
    ActiveRecord::Base.clear_all_connections!
    ActiveRecord::Base.establish_connection( Mysqlplus::Test::CONNECTION_SPEC )
    super
  end  
  
  test "should not establish connections in a lazy manner when warmed up" do
    ActiveRecord::Base.connection_pool.expects(:checkout_new_connection).never
    5.times do
      ActiveRecord::Base.connection_pool.checkout
    end
  end
  
end  