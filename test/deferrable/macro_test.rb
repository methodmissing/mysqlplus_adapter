require "#{File.dirname(__FILE__)}/../helper"
Mysqlplus::Test.prepare!

class MacroTest < ActiveRecord::TestCase

  def teardown
    ActiveRecord::Base.clear_all_connections!
    ActiveRecord::Base.establish_connection(Mysqlplus::Test::CONNECTION)
    super
  end

  def test_should_be_able_to_find_records_in_a_background_thread
    ActiveRecord::Base.connection_pool.expects(:release_connection).twice 
    assert_equal MysqlUser.find(:first, :defer => true), MysqlUser.find(:first) 
    assert_instance_of MysqlUser, MysqlUser.find(:first, :defer => true)
  end

  def test_should_be_able_to_find_records_by_sql_background_thread
    ActiveRecord::Base.connection_pool.expects(:release_connection).once    
    assert_equal MysqlUser.find_by_sql("SELECT * FROM mysql.user WHERE User = 'root'", true), MysqlUser.find(:all, :conditions => ['user.User = ?', 'root'])
  end

  def test_should_be_able_to_preload_related_records_on_multiple_connections
    ActiveRecord::Base.connection_pool.expects(:release_connection).twice
    assert_instance_of MysqlUser, MysqlUser.find( :first, :defer => true, :include => :mysql_user_info)
    sleep(0.5)
  end
    
end

Thread.list.each{|t| t.join unless t == Thread.main }