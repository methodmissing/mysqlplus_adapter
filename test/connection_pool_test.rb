require "#{File.dirname(__FILE__)}/helper"

Mysqlplus::Test.prepare!

class ConnectionPoolTest < ActiveSupport::TestCase
  
  test "should not establish connections in a lazy manner when warmed up" do
    ActiveRecord::Base.connection_pool.expects(:checkout_new_connection).never
    5.times do
      ActiveRecord::Base.connection_pool.checkout
    end
  end
  
end  