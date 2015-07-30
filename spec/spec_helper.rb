# encoding: UTF-8

require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'expert'
Expert.environment.require_all

require 'pry-nav'
require 'erb'
require 'rspec'
require 'factory_girl'
require 'rosette/data_stores/active_record_data_store'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  factory_path = File.expand_path(
    './factories', File.dirname(__FILE__)
  )

  Phrase = Rosette::DataStores::ActiveRecordDataStore::Phrase
  CommitLog = Rosette::DataStores::ActiveRecordDataStore::CommitLog
  CommitLogLocale = Rosette::DataStores::ActiveRecordDataStore::CommitLogLocale

  FactoryGirl.definition_file_paths = [factory_path]
  Dir.glob("#{factory_path}/*.rb").each { |f| require f }

  ActiveRecord::Base.establish_connection(
    YAML.load(
      ERB.new(
        File.read(
          File.expand_path('database.yml', File.dirname(__FILE__))
        )
      ).result
    )
  )

  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
