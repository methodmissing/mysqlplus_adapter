# coding: utf-8

require 'rake'
require 'rake/testtask'
require 'test/helper'

task :default => [:test_mysqlplus, :test_deferrable]

Rake::TestTask.new( "test_mysqlplus" ) { |t|
  t.libs << AR_TEST_SUITE << Mysqlplus::Test.mysqlplus_connection()
  t.test_files = Mysqlplus::Test.active_record_test_files()
  t.verbose = true
}

Rake::TestTask.new( "test_deferrable" ) { |t|
  t.libs << 'lib'
  t.test_files = Mysqlplus::Test.test_files()
  t.verbose = true
}

namespace :mysqplus do
  task :test => "test_mysqlplus"

  desc 'Build the MySQL test databases'
  task :build_databases do
    %x( mysqladmin --user=#{MYSQL_DB_USER} create activerecord_unittest )
    %x( mysqladmin --user=#{MYSQL_DB_USER} create activerecord_unittest2 )
  end

  desc 'Drop the MySQL test databases'
  task :drop_databases do
    %x( mysqladmin --user=#{MYSQL_DB_USER} -f drop activerecord_unittest )
    %x( mysqladmin --user=#{MYSQL_DB_USER} -f drop activerecord_unittest2 )
  end

  desc 'Rebuild the MySQL test databases'
  task :rebuild_databases => [:drop_databases, :build_databases]

end
task :build_mysqlplus_databases => 'mysqlplus:build_databases'
task :drop_mysqlplus_databases => 'mysqlplus:drop_databases'
task :rebuild_mysqlplus_databases => 'mysqlplus:rebuild_databases'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "mysqlplus_adapter"
    s.summary = "ActiveRecord Mysqlplus Adapter"
    s.email = "lourens@methodmissing.com"
    s.homepage = "http://github.com/methodmissing/mysqplus_adapter"
    s.description = "ActiveRecord Mysqlplus Adapter"
    s.authors = ["Lourens Naudé"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end