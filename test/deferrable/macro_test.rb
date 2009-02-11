require "#{File.dirname(__FILE__)}/../helper"

Mysqlplus::Test.prepare!

class MacroTest < ActiveSupport::TestCase

  def teardown
    ActiveRecord::Base.clear_all_connections!
    ActiveRecord::Base.establish_connection( Mysqlplus::Test::CONNECTION_SPEC )
    super
  end

  test "should be able to find records in a background thread" do
    ActiveRecord::Base.connection_pool.expects(:release_connection).twice 
    assert_equal MysqlUser.find(:first, :defer => true), MysqlUser.find(:first) 
    assert_instance_of MysqlUser, MysqlUser.find(:first, :defer => true)
  end

  test "should be able to find records by sql background thread" do
    ActiveRecord::Base.connection_pool.expects(:release_connection).once    
    assert_equal MysqlUser.find_by_sql("SELECT * FROM mysql.user WHERE User = 'root'", true), MysqlUser.find(:all, :conditions => ['user.User = ?', 'root'])
  end

  test "should be able to preload related records on multiple connections" do
    ActiveRecord::Base.connection_pool.expects(:release_connection).twice
    assert_instance_of MysqlUser, MysqlUser.find( :first, :defer => true, :include => :mysql_user_info)
    sleep(0.5)
  end
    
end

Thread.list.each{|t| t.join unless t == Thread.main }
