# encoding: UTF-8

require 'rubygems' unless ENV['NO_RUBYGEMS']

require 'bundler'
require 'yaml'
require 'erb'
require 'rspec/core/rake_task'
require 'rubygems/package_task'

require './lib/rosette/data_stores/active_record_data_store'
require './lib/rosette/data_stores/active_record/tasks/schema_manager'

Bundler::GemHelper.install_tasks

task :default => :spec

desc 'Run specs'
RSpec::Core::RakeTask.new do |t|
  t.pattern = './spec/**/*_spec.rb'
end

namespace :db do
  ActiveRecord::Base.establish_connection(
    YAML.load(
      ERB.new(
        File.read(
          File.expand_path('spec/database.yml', File.dirname(__FILE__))
        )
      ).result
    )
  )

  task :setup do
    Rosette::DataStores::ActiveRecordDataStore::SchemaManager.setup
  end

  task :migrate do
    Rosette::DataStores::ActiveRecordDataStore::SchemaManager.migrate
  end

  task :rollback do
    Rosette::DataStores::ActiveRecordDataStore::SchemaManager.rollback
  end
end
