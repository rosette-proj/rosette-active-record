# encoding: UTF-8

class AddCommitLogLocale < ActiveRecord::Migration
  def up
    create_table :commit_log_locales do |t|
      t.string :commit_id, limit: 45, null: false
      t.string :locale, limit: 10, null: false
      t.integer :translated_count, default: 0
      t.timestamps
    end

    add_index :commit_log_locales, [:commit_id]
    add_index :commit_log_locales, [:commit_id, :locale], unique: true
  end

  def down
    drop_table :commit_log_locales
  end
end
