class CreateFavorites < ActiveRecord::Migration
  def change
    create_table :favorites do |t|
      t.references :tweet, :limit => 8
      t.references :user, :limit => 8
    end
  end
end
