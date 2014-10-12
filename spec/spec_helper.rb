# encoding: UTF-8

require 'pry-nav'

require 'rspec'
require 'factory_girl'
require 'rosette/data_stores/active_record_data_store'

RSpec.configure do |config|
  config.mock_with :rr

  config.include FactoryGirl::Syntax::Methods

  factory_path = File.expand_path(
    './factories', File.dirname(__FILE__)
  )

  Phrase = Rosette::DataStores::ActiveRecordDataStore::Phrase
  Translation = Rosette::DataStores::ActiveRecordDataStore::Translation
  CommitLog = Rosette::DataStores::ActiveRecordDataStore::CommitLog

  FactoryGirl.definition_file_paths = [factory_path]
  Dir.glob("#{factory_path}/*.rb").each { |f| require f }

  ActiveRecord::Base.establish_connection(
    YAML.load_file(
      File.expand_path('database.yml', File.dirname(__FILE__))
    )
  )

  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
