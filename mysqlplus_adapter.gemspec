#!/bin/env ruby
require 'rubygems'
 
spec = Gem::Specification.new do |s|
  s.author = "Lourens Naudé"
  s.name = "mysqlplus_adapter"
  s.version = "0.1"
  s.date = "2008-09-21"
  s.summary = "ActiveRecord Mysqlplus Adapter"
  s.requirements = "Mysqlplus gem"
  s.require_path = 'lib'
  s.email = "lourens@methodmissing.com"
  s.homepage = "http://blog.methodmissing.com"
  s.rubyforge_project = ""
  s.has_rdoc = false
  s.files = ['mysqlplus_adapter.gemspec'] + Dir.glob('lib/active_record/connection_adapters/*')
end
 
if __FILE__ == $0
  Gem.manage_gems
  Gem::Builder.new(spec).build
end