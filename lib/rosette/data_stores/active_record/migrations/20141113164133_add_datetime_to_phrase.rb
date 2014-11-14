# encoding: UTF-8

class AddDatetimeToPhrase < ActiveRecord::Migration
  def up
    add_column :phrases, :commit_datetime, :datetime
  end

  def down
    remove_column :phrases, :commit_datetime
  end
end
