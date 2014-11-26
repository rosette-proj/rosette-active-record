# encoding: UTF-8

class AddIndexOnRepoNameAndFile < ActiveRecord::Migration
  def up
    add_index :phrases, [:repo_name, :file]
  end

  def down
    remove_index :phrases, column: [:repo_name, :file]
  end
end
