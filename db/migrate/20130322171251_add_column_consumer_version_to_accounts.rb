class AddColumnConsumerVersionToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :consumer_version, :integer
  end
end
