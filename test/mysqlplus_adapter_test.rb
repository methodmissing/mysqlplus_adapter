require "#{File.dirname(__FILE__)}/helper"

Mysqlplus::Test.prepare!

class MysqlPlusAdapterTest < ActiveSupport::TestCase
    
  test "should be able to execute queries in an async manner" do
    MysqlUser.connection.send_query( "SELECT * FROM mysql.user WHERE User = 'root'" )
    assert_instance_of Mysql::Result, MysqlUser.connection.get_result
  end
  
end