class WikiPages < ActiveRecord::Base
  has_many :revisions, :class_name => "WikiRevisions", :foreign_key => 'page_id' 
  STATUS = {:PROTECTED => 0, :PRIVATE => 1, :PUBLIC => 2, :DELETED => 3}

  WIKI_EXPORT_PATH = Rails.root.join("public/wiki_export")
  WIKI_UPLOAD_PATH = Rails.root.join("public/wiki_upload")

  scope :page_all, where('status in (0, 1, 2)')
  scope :page_guest, where('status in (0, 2)') 

  def self.status_to_s(status_value)
    STATUS.index(status_value).to_s
  end

  def status_to_s
    WikiPages.status_to_s(status)
  end
end
