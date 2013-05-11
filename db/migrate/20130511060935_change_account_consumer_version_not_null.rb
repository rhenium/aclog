class ChangeAccountConsumerVersionNotNull < ActiveRecord::Migration
  def change
    change_column :accounts, :consumer_version, :integer, null: false
  end
end
