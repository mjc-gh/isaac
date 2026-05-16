class AddExpiresAtToAuthTokens < ActiveRecord::Migration[8.1]
  def change
    add_column :auth_tokens, :expires_at, :datetime, null: false
  end
end
