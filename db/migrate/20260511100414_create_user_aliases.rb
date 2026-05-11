# frozen_string_literal: true

class CreateUserAliases < ActiveRecord::Migration[8.1]
  def change
    create_table :user_aliases do |t|
      t.references :user, null: false, foreign_key: true
      t.string :email, null: false

      t.timestamps
    end
    add_index :user_aliases, :email, unique: true
  end
end
