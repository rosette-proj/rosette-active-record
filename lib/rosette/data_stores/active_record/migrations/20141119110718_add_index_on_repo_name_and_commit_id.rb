# encoding: UTF-8

class AddIndexOnRepoNameAndCommitId < ActiveRecord::Migration
  def up
    add_index :phrases, [:repo_name, :commit_id]
  end

  def down
    remove_index :phrases, column: [:repo_name, :commit_id]
  end
end
