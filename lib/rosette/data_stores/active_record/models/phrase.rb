# encoding: UTF-8

module Rosette
  module DataStores
    class ActiveRecordDataStore

      class Phrase < ActiveRecord::Base
        extend ExtractParams
        include Rosette::Core::PhraseIndexPolicy
        include Rosette::Core::PhraseToHash

        has_many :translations

        # eventually include ArelHelpers and remove this method
        def self.[](column)
          arel_table[column]
        end

        def self.lookup(key, meta_key)
          ikey = index_key(key, meta_key)
          ivalue = index_value(key, meta_key)
          where(ikey => ivalue)
        end
      end
    end

  end
end
