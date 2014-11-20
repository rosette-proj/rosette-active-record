# encoding: UTF-8

class AddIndexOnFileAndCommitId < ActiveRecord::Migration
  def up
    add_index :phrases, [:file, :commit_id]
  end

  def down
    remove_index :phrases, column: [:file, :commit_id]
  end
end
