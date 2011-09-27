class WikiController < ApplicationController
  def index
    lists 
    render :template => 'wiki/lists'
  end

  def show
    page
    render :template => 'wiki/page'
  end

  def page
    logger.error "!!#{params[:id]}"
    unless params[:id].nil?
      #@wiki_page = WikiPages.where(:project_id => params[:project_id], :name => params[:id])
      @wiki_page = WikiPages.find_by_project_id_and_name(params[:project_id], params[:id])
      @wiki_html = Wikitext::Parser.new.parse(@wiki_page.content)
      link_proc = lambda { |target| target == 'bar' ? '123' : '456' }
      @wiki_html = Wikitext::Parser.new.parse(@wiki_page.content, 
                     :internal_link_prefix => "/wiwi/",
                     :base_heading_level => 1,
                     :link_proc => link_proc)
      parser = Wikitext::Parser.new
      #parser.internal_link_prefix = "#{root_path}/wiwi/"
      parser.internal_link_prefix = "#{project_wiki_index_path}/"
      @wiki_html = parser.parse(@wiki_page.content)
                     #:internal_link_prefix => "/of/projects/#{params[:project_id]}/wiki",
          #:internal_link_prefix => project_wiki_path(params[:project_id]), 
    end
  end

  def revision_page
    unless params[:rid].nil?
      @wiki_page = WikiPages.find_by_name(params[:id])
      @revision = WikiRevisions.find_by_page_id_and_revision(@wiki_page.id, params[:rid])
      parser = Wikitext::Parser.new
      parser.internal_link_prefix = "#{project_wiki_index_path}/"
      @wiki_html = parser.parse(@revision.content)
      render :template => 'wiki/page'
    end
  end

  def lists
    logger.error "!##{params[:project_id]}"
    @wiki_pages = WikiPages.where(:project_id => params[:project_id])
  end

  def add 
    @wiki_page = WikiPages.find_by_project_id_and_name(params[:project_id], params[:id])
    if @wiki_page.nil?
      edit
      render :template => 'wiki/edit'
    else
      redirect_to :action => 'show'
    end
  end

  def edit
    #logger.error "!!#{params[:id]}"
    @wiki_page = WikiPages.find_by_project_id_and_name(params[:project_id], params[:id])
    if @wiki_page.nil?
      @wiki_page = WikiPages.new
      @wiki_page.name = params[:id]
      @wiki_page.content = params[:wiki_page][:content] unless params[:wiki_page].nil?
    end
    if request.post? 
      if params[:submit_preview]
        @wiki_html = Wikitext::Parser.new.parse(params[:wiki_page][:content])
      else params[:submit_save]
        p = @wiki_page
        p.project_id = params[:project_id]
        p.name = params[:wiki_page][:name] if params[:wiki_page][:name]
        p.content = params[:wiki_page][:content]
        p.revision = (p.revision || 0) + 1
        p.revised_at = Time.now
        p.revised_by = 'Guest'
        p.save

        r = WikiRevisions.new
        r.page_id = p.id
        r.content = p.content
        r.revision = p.revision
        r.revised_at = p.revised_at
        r.revised_by = p.revised_by
        r.save
        redirect_to :id => params[:id] || p.name, :action => 'show'
      end
    end
  end

  def preview
    if request.post? 
      @wiki_html = Wikitext::Parser.new.parse(params[:wiki_page][:content])
    end
  end

  def save
    if request.post? 
      #@wiki_html = Wikitext::Parser.new.parse(params[:wiki_page][:content])
    end
  end

  def delete
  end

  def revisions
    pid = WikiPages.find_by_name(params[:id]).id
    @revisions = WikiRevisions.where(:page_id => pid)
  end

  def export
  end

  def help
  end
end
