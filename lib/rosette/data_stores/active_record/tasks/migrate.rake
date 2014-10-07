# encoding: UTF-8

require 'rosette/data_stores/active_record/tasks/schema_manager'

namespace :rosette do
  namespace :ar do

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
end
