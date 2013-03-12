class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.integer :user_id, :limit => 8, :null => false
      t.string :oauth_token, :null => false
      t.string :oauth_token_secret, :null => false

      t.timestamps
    end

    add_index :accounts, :user_id, :unique => true
  end
end
