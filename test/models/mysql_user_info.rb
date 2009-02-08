class MysqlUserInfo < ActiveRecord::Base  
  set_table_name 'user_info'
  set_primary_key :User
  
  belongs_to :mysql_user, :class_name => 'MysqlUser', :foreign_key => :User
end