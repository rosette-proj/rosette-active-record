# encoding: UTF-8

class AddIndexOnRepoNameAndMetaKey < ActiveRecord::Migration
  def up
    add_index :phrases, [:repo_name, :meta_key]
  end

  def down
    remove_index :phrases, column: [:repo_name, :meta_key]
  end
end
