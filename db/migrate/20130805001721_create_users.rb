class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :screen_name,    limit: 20
      t.string :name,           limit: 64
      t.text :profile_image_url
      t.timestamps
      t.boolean :protected
    end

    add_index :users, :screen_name
  end
end
