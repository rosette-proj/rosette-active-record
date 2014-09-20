# encoding: UTF-8

module Rosette
  module DataStores
    class ActiveRecordDataStore

      class AddPhraseTable < ActiveRecord::Migration
        def up
          create_table :phrases do |t|
            t.string :commit_id, limit: 45, null: false
            t.text :key, null: false
            t.string :meta_key, limit: 255
            t.string :file, limit: 255, null: false
            t.string :repo_name, limit: 100
            t.timestamps
          end

          add_index :phrases, [:commit_id, :meta_key, :file, :repo_name], unique: true
        end

        def down
          drop_table :phrases
        end
      end

    end
  end
end
