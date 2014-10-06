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

          add_index :translations, [:phrase_id, :locale, :translation], length: { translation: 255 }
        end

        def down
          drop_table :translations
        end
      end

    end
  end
end
