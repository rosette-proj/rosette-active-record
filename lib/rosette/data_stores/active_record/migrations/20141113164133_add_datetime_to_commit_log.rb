# encoding: UTF-8

class AddDatetimeToCommitLog < ActiveRecord::Migration
  def up
    add_column :commit_logs, :commit_datetime, :datetime
  end

  def down
    remove_column :commit_logs, :commit_datetime
  end
end
