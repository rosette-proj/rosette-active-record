# encoding: UTF-8

class AddIndexOnCommitIdAndCommitDatetime < ActiveRecord::Migration
  def up
    add_index :commit_logs, [:commit_id, :commit_datetime]
  end

  def down
    remove_index :commit_logs, column: [:commit_id, :commit_datetime]
  end
end
