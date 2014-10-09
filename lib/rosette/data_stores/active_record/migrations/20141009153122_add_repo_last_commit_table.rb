# encoding: UTF-8

class AddRepoLastCommitTable < ActiveRecord::Migration
  def up
    create_table :repo_last_commits do |t|
      t.string :repo_name, limit: 100
      t.string :last_commit_id, limit: 45, null: false
      t.timestamps
    end

    add_index :repo_last_commits, [:repo_name], unique: true
  end

  def down
    drop_table :repo_last_commits
  end
end

