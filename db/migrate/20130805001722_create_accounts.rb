class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.integer :user_id,           limit: 8,   null: false
      t.string :oauth_token,                    null: false
      t.string :oauth_token_secret,             null: false
      t.timestamps
      t.integer :consumer_version,              null: false
      t.boolean :notification,                  null: false, default: true
      t.boolean :private,                       null: false, default: false
      t.integer :status,            limit: 2,   null: false, default: 0
    end

    add_index :accounts, :user_id, unique: true
  end
end
