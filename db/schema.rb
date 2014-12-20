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

ActiveRecord::Schema.define(version: 20141220025331) do

  create_table "accounts", force: true do |t|
    t.integer  "user_id",              limit: 8,                  null: false
    t.string   "oauth_token",          limit: 255,                null: false
    t.string   "oauth_token_secret",   limit: 255,                null: false
    t.boolean  "notification_enabled", limit: 1,   default: true, null: false
    t.integer  "status",               limit: 2,   default: 0,    null: false
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  add_index "accounts", ["status"], name: "index_accounts_on_status", using: :btree
  add_index "accounts", ["user_id"], name: "index_accounts_on_user_id", unique: true, using: :btree

  create_table "favorites", force: true do |t|
    t.integer "tweet_id", limit: 8, null: false
    t.integer "user_id",  limit: 8, null: false
  end

  add_index "favorites", ["tweet_id"], name: "index_favorites_on_tweet_id", using: :btree
  add_index "favorites", ["user_id", "tweet_id"], name: "index_favorites_on_user_id_and_tweet_id", unique: true, using: :btree

  create_table "retweets", force: true do |t|
    t.integer "tweet_id", limit: 8, null: false
    t.integer "user_id",  limit: 8, null: false
  end

  add_index "retweets", ["tweet_id"], name: "index_retweets_on_tweet_id", using: :btree
  add_index "retweets", ["user_id"], name: "index_retweets_on_user_id", using: :btree

  create_table "tweets", force: true do |t|
    t.text     "text",            limit: 65535,             null: false
    t.text     "source",          limit: 65535,             null: false
    t.integer  "user_id",         limit: 8,                 null: false
    t.datetime "tweeted_at",                                null: false
    t.integer  "favorites_count", limit: 4,     default: 0, null: false
    t.integer  "retweets_count",  limit: 4,     default: 0, null: false
    t.integer  "reactions_count", limit: 4,     default: 0, null: false
    t.integer  "in_reply_to_id",  limit: 8
  end

  add_index "tweets", ["in_reply_to_id"], name: "index_tweets_on_in_reply_to_id", using: :btree
  add_index "tweets", ["reactions_count"], name: "index_tweets_on_reactions_count", using: :btree
  add_index "tweets", ["user_id", "reactions_count"], name: "index_tweets_on_user_id_and_reactions_count", using: :btree

  create_table "users", force: true do |t|
    t.string   "screen_name",       limit: 20,  null: false
    t.string   "name",              limit: 64,  null: false
    t.string   "profile_image_url", limit: 255, null: false
    t.boolean  "protected",         limit: 1,   null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "users", ["screen_name"], name: "index_users_on_screen_name", using: :btree

end
