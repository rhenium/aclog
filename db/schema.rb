# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20130323045606) do

  create_table "accounts", force: true do |t|
    t.integer  "user_id",            limit: 8, null: false
    t.string   "oauth_token",                  null: false
    t.string   "oauth_token_secret",           null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "consumer_version"
  end

  add_index "accounts", ["user_id"], name: "index_accounts_on_user_id", unique: true

  create_table "favorites", force: true do |t|
    t.integer "tweet_id", limit: 8, null: false
    t.integer "user_id",  limit: 8, null: false
  end

  add_index "favorites", ["tweet_id", "user_id"], name: "index_favorites_on_tweet_id_and_user_id", unique: true
  add_index "favorites", ["tweet_id"], name: "index_favorites_on_tweet_id"
  add_index "favorites", ["user_id"], name: "index_favorites_on_user_id"

  create_table "retweets", force: true do |t|
    t.integer "tweet_id", limit: 8, null: false
    t.integer "user_id",  limit: 8, null: false
  end

  add_index "retweets", ["tweet_id"], name: "index_retweets_on_tweet_id"
  add_index "retweets", ["user_id"], name: "index_retweets_on_user_id"

  create_table "tweets", force: true do |t|
    t.text     "text",                                  null: false
    t.text     "source"
    t.integer  "user_id",         limit: 8,             null: false
    t.datetime "tweeted_at"
    t.integer  "favorites_count",           default: 0
    t.integer  "retweets_count",            default: 0
  end

  create_table "users", force: true do |t|
    t.string   "screen_name"
    t.string   "name"
    t.text     "profile_image_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "protected"
  end

  add_index "users", ["screen_name"], name: "index_users_on_screen_name"

end
