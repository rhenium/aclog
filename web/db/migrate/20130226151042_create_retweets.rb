class CreateRetweets < ActiveRecord::Migration
  def change
    create_table :retweets do |t|
      t.references :tweet, :limit => 8
      t.references :user, :limit => 8
    end
  end
end
