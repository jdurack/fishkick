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

ActiveRecord::Schema.define(version: 20140505005357) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admins", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "admins", ["email"], name: "index_admins_on_email", unique: true, using: :btree
  add_index "admins", ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true, using: :btree

  create_table "fish", force: true do |t|
    t.string   "name"
    t.string   "image"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fish_score", force: true do |t|
    t.integer  "site_id"
    t.integer  "fish_id"
    t.datetime "date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reports", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "site_fish_info", force: true do |t|
    t.integer  "site_id"
    t.integer  "fish_id"
    t.decimal  "baseScoreJan", precision: 2, scale: 2
    t.decimal  "baseScoreFeb", precision: 2, scale: 2
    t.decimal  "baseScoreMar", precision: 2, scale: 2
    t.decimal  "baseScoreApr", precision: 2, scale: 2
    t.decimal  "baseScoreMay", precision: 2, scale: 2
    t.decimal  "baseScoreJun", precision: 2, scale: 2
    t.decimal  "baseScoreJul", precision: 2, scale: 2
    t.decimal  "baseScoreAug", precision: 2, scale: 2
    t.decimal  "baseScoreSep", precision: 2, scale: 2
    t.decimal  "baseScoreOct", precision: 2, scale: 2
    t.decimal  "baseScoreNov", precision: 2, scale: 2
    t.decimal  "baseScoreDec", precision: 2, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "site_image", force: true do |t|
    t.integer  "site_id"
    t.string   "image"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sites", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "name_url"
    t.string   "description"
  end

  add_index "sites", ["name_url"], name: "index_sites_on_name_url", using: :btree

end
