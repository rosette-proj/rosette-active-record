# encoding: UTF-8

module Rosette
  module DataStores
    class ActiveRecordDataStore

      class Translation < ActiveRecord::Base
        extend ExtractParams
        include Rosette::Core::TranslationToHash

        validates :translation, length: { minimum: 0 }, presence: true
        validates :phrase_id, presence: true
        validates :locale, presence: true

        belongs_to :phrase

        # eventually include ArelHelpers and remove this method
        def self.[](column)
          arel_table[column]
        end

        def self.from_h(hash)
          hash[:phrase] = Phrase.new(hash[:phrase])
          new(hash)
        end
      end

    end
  end
end
