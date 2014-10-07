# encoding: UTF-8

require 'rubygems' unless ENV['NO_RUBYGEMS']

require 'bundler'
require 'yaml'
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
    YAML.load_file(
      File.expand_path('spec/database.yml', File.dirname(__FILE__))
    )
  )

  task :setup do
    SchemaManager.setup
  end

  task :migrate do
    SchemaManager.migrate
  end

  task :rollback do
    SchemaManager.rollback
  end
end
