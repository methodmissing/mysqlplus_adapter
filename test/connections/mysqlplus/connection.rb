print "Using mysqplus\n"
require "#{File.dirname(__FILE__)}/../../helper"
require_dependency "#{AR_TEST_SUITE}/models/course"
require 'logger'

ActiveRecord::Base.logger = Logger.new("debug.log")

# GRANT ALL PRIVILEGES ON activerecord_unittest.* to 'rails'@'localhost';
# GRANT ALL PRIVILEGES ON activerecord_unittest2.* to 'rails'@'localhost';

ActiveRecord::Base.configurations = {
  'arunit' => {
    :adapter  => 'mysqlplus',
    :username => 'rails',
    :encoding => 'utf8',
    :database => 'activerecord_unittest',
    :pool => 5,
    :warmup => true
  },
  'arunit2' => {
    :adapter  => 'mysqlplus',
    :username => 'rails',
    :database => 'activerecord_unittest2',
    :pool => 5,
    :warmup => true
  }
}

ActiveRecord::Base.establish_connection 'arunit'
Course.establish_connection 'arunit2'