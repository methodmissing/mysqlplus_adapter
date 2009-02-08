class MysqlUser < ActiveRecord::Base  
  set_table_name 'user'
  set_primary_key :User
  
  has_one :mysql_user_info, :class_name => 'MysqlUserInfo', :foreign_key => :User
end