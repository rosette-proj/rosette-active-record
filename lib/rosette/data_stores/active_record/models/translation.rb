# encoding: UTF-8

module Rosette
  module DataStores
    class ActiveRecordDataStore

      class Translation < ActiveRecord::Base
        extend ExtractParams

        validates :translation, presence: true
        validates :phrase_id, presence: true
        validates :locale, presence: true

        belongs_to :phrase

        # eventually include ArelHelpers and remove this method
        def self.[](column)
          arel_table[column]
        end
      end

    end
  end
end
