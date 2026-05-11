class CreateAuthTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :auth_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.json :scopes, default: []
      t.string :access_token, null: false
      t.string :refresh_token

      t.timestamps
    end
    add_index :auth_tokens, [:user_id, :provider], unique: true
  end
end
