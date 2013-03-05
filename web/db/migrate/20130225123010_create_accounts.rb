class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.string :oauth_token
      t.string :oauth_token_secret

      t.timestamps
    end
  end
end
