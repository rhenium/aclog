class CreateIssues < ActiveRecord::Migration
  def change
    create_table :issues do |t|
      t.integer :issue_type, :limit => 2
      t.integer :status, :limit => 2
      t.text :data

      t.timestamps
    end

    add_index :issues, :issue_type
    add_index :issues, :status
  end
end
