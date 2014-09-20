# encoding: UTF-8

require 'pry-nav'

namespace :rosette do
  namespace :ar do

    class SchemaMigration < ActiveRecord::Base
      primary_key = :version
    end

    def migration_files_path
      File.expand_path('../../migrations', __FILE__)
    end

    def migration_files
      Dir.glob(File.join(migration_files_path, '**/*.rb'))
    end

    def connection
      ActiveRecord::Base.connection
    end

    def migrations_table_exists?
      connection.tables.include?('schema_migrations')
    end

    def create_migrations_table
      connection.create_table('schema_migrations') do |t|
        t.string(:version, length: 256)
      end

      connection.add_index(:schema_migrations, :version, unique: true)
    end

    def file_versions
      migration_files.map do |file_name|
        version_from(file_name)
      end
    end

    def version_from(file_name)
      File.basename(file_name).gsub(/\.rb\z/, '')
    end

    def file_from(version)
      "#{version}.rb"
    end

    def path_from(version)
      File.join(migration_files_path, file_from(version))
    end

    def completed_versions
      SchemaMigration.pluck(:version)
    end

    def pending_migrations
      file_versions - completed_versions
    end

    def data_store_namespace
      Rosette::DataStores::ActiveRecordDataStore
    end

    def data_store_constants
      data_store_namespace.constants
    end

    def each_pending_migration
      previous_migration_classes = data_store_constants

      pending_migrations.sort.each do |version|
        file = path_from(version)
        load file
        migration_class_diff = data_store_constants - previous_migration_classes

        if migration_class = migration_class_diff.first
          yield version, data_store_namespace.const_get(migration_class)
        end

        previous_migration_classes = data_store_constants
      end
    end

    task :setup do
      unless migrations_table_exists?
        create_migrations_table
      end
    end

    task :migrate do
      each_pending_migration do |version, migration_class|
        ActiveRecord::Base.transaction do
          migration_class.new.up
          SchemaMigration.create(version: version)
        end
      end
    end

    task :rollback do
      if record = SchemaMigration.last
        previous_migration_classes = data_store_constants
        file = path_from(record.version)

        load file
        migration_class_diff = data_store_constants - previous_migration_classes

        if migration_class = migration_class_diff.first
          migration_const = data_store_namespace.const_get(migration_class)

          ActiveRecord::Base.transaction do
            migration_const.new.down
            record.destroy
          end
        end
      end
    end

  end
end
