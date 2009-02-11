require "#{File.dirname(__FILE__)}/../helper"

Mysqlplus::Test.prepare!

class ResultTest < ActiveSupport::TestCase
  
  def teardown
    ActiveRecord::Base.clear_all_connections!
    ActiveRecord::Base.establish_connection( Mysqlplus::Test::CONNECTION_SPEC )
    super
  end
  
  test "should be able to raise exceptions from the background Thread" do
    assert_raises( StandardError ) do
      ActiveRecord::Deferrable::Result.new do
        raise StandardError
      end.to_s
    end  
  end 
  
  test "should release the checked out connection for the background Thread at all times" do
    ActiveRecord::Base.connection_pool.expects(:release_connection).once
    ActiveRecord::Deferrable::Result.new do
      raise StandardError
    end
  end
  
  test "should only block when an immediate result is required" do
    ActiveRecord::Deferrable::Result.any_instance.expects(:validate!).never
    ActiveRecord::Deferrable::Result.new do
      sleep(5)
    end
  end
  
end