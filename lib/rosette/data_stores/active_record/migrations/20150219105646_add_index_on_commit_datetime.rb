# encoding: UTF-8

class AddIndexOnCommitDatetime < ActiveRecord::Migration
  def up
    add_index :commit_logs, [:commit_datetime]
  end

  def down
    remove_index :commit_logs, column: [:commit_datetime]
  end
end
