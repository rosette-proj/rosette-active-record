# encoding: UTF-8

require 'rosette/data_stores/active_record/tasks/schema_manager'

namespace :rosette do
  namespace :ar do

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
end
