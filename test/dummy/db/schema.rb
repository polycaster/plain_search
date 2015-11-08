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

ActiveRecord::Schema.define(version: 20151013022315) do

  create_table "companies", force: :cascade do |t|
    t.string "name"
  end

  create_table "dossiers", force: :cascade do |t|
    t.string "filename"
  end

  create_table "employees", force: :cascade do |t|
    t.integer "company_id"
    t.string  "first_name"
    t.string  "last_name"
    t.string  "address"
    t.string  "zip_code"
    t.string  "city"
    t.string  "state"
    t.string  "phone"
    t.string  "email"
    t.string  "profession"
  end

  create_table "search_terms", force: :cascade do |t|
    t.string  "term"
    t.string  "source"
    t.integer "findable_id"
    t.string  "findable_type"
  end

  add_index "search_terms", ["source"], name: "index_search_terms_on_source"
  add_index "search_terms", ["term"], name: "index_search_terms_on_term"

end
