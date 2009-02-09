# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{mysqlplus_adapter}
  s.version = "1.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Lourens Naud\303\251"]
  s.date = %q{2009-02-09}
  s.description = %q{ActiveRecord Mysqlplus Adapter}
  s.email = %q{lourens@methodmissing.com}
  s.files = ["README.textile", "VERSION.yml", "lib/active_record", "lib/active_record/connection_adapters", "lib/active_record/connection_adapters/mysqlplus_adapter", "lib/active_record/connection_adapters/mysqlplus_adapter/connection_pool.rb", "lib/active_record/connection_adapters/mysqlplus_adapter/deferrable", "lib/active_record/connection_adapters/mysqlplus_adapter/deferrable/macro.rb", "lib/active_record/connection_adapters/mysqlplus_adapter/deferrable/result.rb", "lib/active_record/connection_adapters/mysqlplus_adapter.rb", "test/connections", "test/connections/mysqlplus", "test/connections/mysqlplus/connection.rb", "test/deferrable", "test/deferrable/macro_test.rb", "test/helper.rb", "test/models", "test/models/mysql_user.rb", "test/models/mysql_user_info.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/methodmissing/mysqplus_adapter}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{ActiveRecord Mysqlplus Adapter}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
