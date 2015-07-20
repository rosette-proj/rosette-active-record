# encoding: UTF-8

class AddBranchNameToCommitLog < ActiveRecord::Migration
  def up
    add_column :commit_logs, :branch_name, :string
  end

  def down
    remove_column :commit_logs, :branch_name
  end
end
