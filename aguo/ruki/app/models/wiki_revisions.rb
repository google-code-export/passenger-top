class WikiRevisions < ActiveRecord::Base
  #belongs_to :wiki_pages, :foreign_key => 'page_id'
  belongs_to :page, :class_name => 'WikiPages', :foreign_key => 'page_id'
end
