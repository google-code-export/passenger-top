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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110819055920) do

  create_table "projects", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at"
  end

  create_table "wiki_pages", :force => true do |t|
    t.integer  "project_id"
    t.string   "name"
    t.string   "content"
    t.integer  "revision"
    t.string   "locked_by"
    t.datetime "locked_at"
    t.string   "revised_by"
    t.datetime "revised_at"
    t.datetime "created_at", :null => false
    t.datetime "updated_at"
  end

  create_table "wiki_revisions", :force => true do |t|
    t.integer  "page_id"
    t.string   "content"
    t.integer  "revision"
    t.string   "revised_by"
    t.datetime "revised_at"
    t.datetime "created_at", :null => false
    t.datetime "updated_at"
  end

end
