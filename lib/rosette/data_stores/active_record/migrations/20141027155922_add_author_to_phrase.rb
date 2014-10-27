# encoding: UTF-8

class AddAuthorToPhrase < ActiveRecord::Migration
  def up
    add_column :phrases, :author_name, :string
    add_column :phrases, :author_email, :string
  end

  def down
    remove_column :phrases, :author_name
    remove_column :phrases, :author_email
  end
end
