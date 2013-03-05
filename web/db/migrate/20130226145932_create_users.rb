class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :screen_name
      t.string :name
      t.text :profile_image_url

      t.timestamps
    end

    add_index :users, :screen_name
  end
end
