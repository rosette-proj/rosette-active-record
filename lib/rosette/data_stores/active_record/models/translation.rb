# encoding: UTF-8

module Rosette
  module DataStores
    class ActiveRecordDataStore

      class Translation < ActiveRecord::Base
        extend ExtractParams
        include Rosette::Core::TranslationToHash

        validate  :validate_translation_presence
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

        private

        def validate_translation_presence
          if translation.nil?
            errors.add(:translation, "can't be nil")
          end
        end
      end

    end
  end
end
