class CreateWiki < ActiveRecord::Migration
  def self.up
    create_table "projects", :force => true do |t|
      t.integer "id"
      t.string  "name"
      t.datetime "created_at",  :null => false, :default => 'now()'
      t.datetime "updated_at"
    end

    create_table "wiki_pages", :force => true do |t|
      t.integer  "id"
      t.integer  "project_id"
      t.string   "name"
      t.string   "summary"
      t.text     "content"
      t.integer  "revision"
      t.string   "log"
      t.string   "locked_by"
      t.datetime "locked_at"
      t.string   "revised_by"
      t.datetime "revised_at"
      t.integer  "status"
      t.datetime "created_at",  :null => false
      t.datetime "updated_at"
    end

    create_table "wiki_revisions", :force => true do |t|
      t.integer  "id"
      t.integer  "page_id"
      t.text     "content"
      t.integer  "revision"
      t.string   "log"
      t.string   "revised_by"
      t.datetime "revised_at"
      t.datetime "created_at",  :null => false
      t.datetime "updated_at"
    end

  end

  def self.down
    %w(projects wiki_pages wiki_revisions).each do |table_name|
      drop_table table_name
    end
  end
end
