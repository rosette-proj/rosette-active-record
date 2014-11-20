# encoding: UTF-8

class AddLineNumberToPhrase < ActiveRecord::Migration
  def up
    add_column :phrases, :line_number, :integer
  end

  def down
    remove_column :phrases, :line_number
  end
end
