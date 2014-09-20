# encoding: UTF-8

module Rosette
  module DataStores
    class ActiveRecordDataStore

      class Translation < ActiveRecord::Base
        extend ExtractParams
        include Rosette::Core::PhraseIndexPolicy
        include Rosette::Core::PhraseToHash

        belongs_to :phrase

        # eventually include ArelHelpers and remove this method
        def self.[](column)
          arel_table[column]
        end
      end

    end
  end
end
