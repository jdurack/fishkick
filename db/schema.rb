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

ActiveRecord::Schema.define(version: 20140520001512) do

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
    t.boolean  "is_active"
  end

  create_table "fish_scores", force: true do |t|
    t.integer  "site_id"
    t.integer  "fish_id"
    t.datetime "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "value"
  end

  add_index "fish_scores", ["site_id", "fish_id", "date"], name: "index_fish_scores_on_site_id_and_fish_id_and_date", unique: true, using: :btree

  create_table "guides", force: true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "phone_number"
    t.string   "email_address"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_active"
    t.string   "primary_image"
  end

  create_table "report_data", force: true do |t|
    t.integer  "site_id"
    t.integer  "report_data_parameter_id"
    t.datetime "datetime"
    t.decimal  "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "report_data", ["site_id", "report_data_parameter_id", "datetime"], name: "data_point_unique_index", unique: true, using: :btree

  create_table "report_data_parameters", force: true do |t|
    t.string   "name"
    t.string   "usgs_parameter_code"
    t.string   "units"
    t.string   "units_abbreviation"
    t.boolean  "is_active"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reports", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "site_fish_infos", force: true do |t|
    t.integer  "site_id"
    t.integer  "fish_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_active"
    t.decimal  "month_value_0"
    t.decimal  "month_value_1"
    t.decimal  "month_value_2"
    t.decimal  "month_value_3"
    t.decimal  "month_value_4"
    t.decimal  "month_value_5"
    t.decimal  "month_value_6"
    t.decimal  "month_value_7"
    t.decimal  "month_value_8"
    t.decimal  "month_value_9"
    t.decimal  "month_value_10"
    t.decimal  "month_value_11"
    t.integer  "max_score"
  end

  add_index "site_fish_infos", ["site_id", "fish_id"], name: "index_site_fish_infos_on_site_id_and_fish_id", unique: true, using: :btree

  create_table "site_images", force: true do |t|
    t.integer  "site_id"
    t.string   "image"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "site_precipitation_data", force: true do |t|
    t.integer  "site_id"
    t.decimal  "value"
    t.boolean  "is_forecast"
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "site_precipitation_data", ["site_id", "date", "is_forecast"], name: "site_precipitation_point_unique_index", unique: true, using: :btree

  create_table "sites", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "name_url"
    t.text     "description"
    t.text     "map_polygon_data"
    t.text     "latitude"
    t.text     "longitude"
    t.boolean  "is_active"
    t.integer  "water_body_type",  default: 0
    t.string   "usgs_site_id"
    t.string   "primary_image"
  end

  add_index "sites", ["name_url"], name: "index_sites_on_name_url", using: :btree

end
