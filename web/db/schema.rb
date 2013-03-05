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

ActiveRecord::Schema.define(version: 20130226151042) do

  create_table "accounts", force: true do |t|
    t.string   "oauth_token"
    t.string   "oauth_token_secret"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "favorites", force: true do |t|
    t.integer "tweet_id", limit: 8
    t.integer "user_id",  limit: 8
  end

  create_table "retweets", force: true do |t|
    t.integer "tweet_id", limit: 8
    t.integer "user_id",  limit: 8
  end

  create_table "tweets", force: true do |t|
    t.text     "text"
    t.text     "source"
    t.integer  "user_id",         limit: 8
    t.datetime "tweeted_at"
    t.integer  "favorites_count"
    t.integer  "retweets_count"
  end

  create_table "users", force: true do |t|
    t.string   "screen_name"
    t.string   "name"
    t.text     "profile_image_url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["screen_name"], name: "index_users_on_screen_name"

end
