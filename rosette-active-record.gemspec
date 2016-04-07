$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'rosette/data_stores/active_record/version'

Gem::Specification.new do |s|
  s.name     = 'rosette-active-record'
  s.version  = ::Rosette::DataStores::ActiveRecordDataStore::VERSION
  s.authors  = ['Cameron Dutro']
  s.email    = ['camertron@gmail.com']
  s.homepage = 'http://github.com/camertron'

  s.description = s.summary = 'An ActiveRecord-backed datastore for the Rosette internationalization platform.'

  s.add_dependency 'activerecord'

  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true

  s.require_path = 'lib'
  s.files = Dir["{lib,spec}/**/*", 'Gemfile', 'History.txt', 'README.md', 'Rakefile', 'rosette-active-record.gemspec']
end
