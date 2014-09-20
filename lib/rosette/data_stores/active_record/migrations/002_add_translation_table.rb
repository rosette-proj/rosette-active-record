# encoding: UTF-8

module Rosette
  module DataStores
    class ActiveRecordDataStore

      class AddTranslationTable < ActiveRecord::Migration
        def up
          create_table :translations do |t|
            t.references :phrase
            t.string :locale, limit: 10
            t.text :translation
            t.timestamps
          end
        end

        def down
          drop_table :translations
        end
      end

    end
  end
end
