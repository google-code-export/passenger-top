require 'zip/zip'
require 'net/http'
require 'fileutils'

class WikiController < ApplicationController
  #require 'RMagick'
  #include Magick
  include ActionView::Helpers::NumberHelper
  before_filter :timezone
  before_filter :check_permission

  def timezone
    Time.zone = 8 
    I18n.locale = session['wiki_lang'] || "zh_TW"
    @wiki_permit = fpermit?("wiki", params[:project_id])
    @project = Projects.find_by_id(params[:project_id])
    if @project.nil?
      flash[:warning] = "project is not exists."
      redirect_to :controller => :projects
      return
    end
  end

  def index
    redirect_to :action => :show, :id => 'HomePage' 
  end

  def show
    page
  end

  #show wiki page content
  def page
    unless params[:id].nil?
      @wiki_page = WikiPages.page_all.find_by_project_id_and_name(params[:project_id], params[:id])
      if @wiki_page
        #Is private page
        if @wiki_permit == false and @wiki_page.status == WikiPages::STATUS[:PRIVATE]
          flash[:warning] = t("is private page", :name => @wiki_page.name, :scope => 'wiki.message')
          redirect_to :action => 'list'
          return
        end
        #show revision page
        unless params[:r].nil?
          @revision = WikiRevisions.find_by_page_id_and_revision(@wiki_page.id, params[:r])
          @wiki_page.content = @revision.content unless @revision.nil?
        end
        parser = Wikitext::Parser.new
        parser.internal_link_prefix = "#{project_wiki_index_path}/"
        parser.img_prefix = "#{root_path}/wiki_upload/#{params[:project_id]}/"
        @wiki_html = parser.parse(@wiki_page.content)
      elsif @wiki_permit #No HomePage and has permit
        redirect_to :action => 'edit'
        return
      else #No HomePage and no permit
        @wiki_page = WikiPages.new
        @wiki_page.name = "HomePage"
        @wiki_html = t("This page is no content", :scope => 'wiki.message') + "<br/></br/></br>"
      end
      render :template => 'wiki/page'
    end
  end

  #will remove?
  #def revision_page
  #  unless params[:rid].nil?
  #    @wiki_page = WikiPages.find_by_name(params[:id])
  #    @revision = WikiRevisions.find_by_page_id_and_revision(@wiki_page.id, params[:rid])
  #    parser = Wikitext::Parser.new
  #    parser.internal_link_prefix = "#{project_wiki_index_path}/"
  #    @wiki_html = parser.parse(@revision.content)
  #    render :template => 'wiki/page'
  #  end
  #end

  def list
    if request.post? and !params[:page_id].nil? and @wiki_permit
      if params[:submit_delete] or params[:submit_protected] or 
         params[:submit_private] or params[:submit_public]
        ActiveRecord::Base.transaction do
          params[:page_id].each do |pid|
            wp = WikiPages.page_all.where(:project_id => params[:project_id]).where(:id => pid)
            if wp[0]
              if params[:submit_delete]
                wp[0].status = WikiPages::STATUS[:DELETED] 
              elsif params[:submit_protected]
                wp[0].status = WikiPages::STATUS[:PROTECTED] 
              elsif params[:submit_private]
                wp[0].status = WikiPages::STATUS[:PRIVATE] 
              elsif params[:submit_public]
                wp[0].status = WikiPages::STATUS[:PUBLIC] 
              end
              if wp[0].name == 'HomePage' and params[:submit_private]
                flash.now[:warning] = "頁面 HomePage 不能設為私有頁面"
              else
                wp[0].save
              end
            end
          end
        end
      elsif params[:submit_export_html]
        export_html
      elsif params[:submit_export_pdf]
        export_pdf
      elsif params[:submit_export_wiki]
        export_wiki
      end
    end

    if @wiki_permit
      @wiki_pages = WikiPages.page_all.where(:project_id => params[:project_id])
    else
      @wiki_pages = WikiPages.page_guest.where(:project_id => params[:project_id])
    end
    
    if params[:search]
      @wiki_pages = @wiki_pages.where("(name like '%#{params[:search]}%' " + 
                                      "or summary like '%#{params[:search]}%' " +
                                      "or content like '%#{params[:search]}%')")
    end
    @search = params[:search]
  end

  def edit
    ActionView::Base.send(:include, Recaptcha::ClientHelper)
    ActionController::Base.send(:include, Recaptcha::Verify)

    @wiki_page = WikiPages.page_all.find_by_project_id_and_name(params[:project_id], params[:id])
    if @wiki_page.nil? #page not exists.
      unless @wiki_permit
        flash[:warning] = t("No Permission", :scope => 'wiki.message')
        redirect_to :action => 'list'
        return
      end
      @wiki_page = WikiPages.new
      @wiki_page.name = params[:id]
      @wiki_page.status = WikiPages::STATUS[:PROTECTED]
    elsif @wiki_permit == false and @wiki_page.status != WikiPages::STATUS[:PUBLIC]
      flash[:warning] = t("No Permission", :scope => 'wiki.message')
      redirect_to :action => 'list'
      return
    end

    wp = @wiki_page
    if request.post? 
      wp.name = params[:wiki_page][:name]
      wp.summary = params[:wiki_page][:summary]
      wp.content = params[:wiki_page][:content]
      wp.log = params[:wiki_page][:log]
      if params[:submit_preview]
        parser = Wikitext::Parser.new
        parser.internal_link_prefix = "#{project_wiki_index_path}/"
        parser.img_prefix = "#{root_path}/wiki_upload/#{params[:project_id]}/"
        @wiki_html = parser.parse(wp.content)
      else params[:submit_save]
        err_msg = ''
        if params[:wiki_page][:name] == 'NoName'
          err_msg += t('Please input a new page name', :scope => 'wiki.message') + '</br>'
        end
        if params[:wiki_page][:content].strip == ""
          err_msg += t('Please input content', :scope => 'wiki.message') + '</br>'
        end
        if params[:wiki_page][:name].strip == ""
          err_msg += t('Please input page name', :scope => 'wiki.message') + '</br>'
        end
        unless WikiPages.page_all.
                 where(:project_id => params[:project_id]).
                 where(:name => params[:wiki_page][:name]).
                 where("id <> '#{wp.id}'").empty? 
          err_msg += t('Page name already exist', :scope => 'wiki.message') + '</br>'
        end
        if err_msg != ""
          flash.now[:warning] = err_msg.html_safe
          return
        end
        if current_user.login == 'guest' and verify_recaptcha == false
          flash.now[:warning] = t('Please confirm captcha', :scope => 'wiki.message') 
          return
        end

        wp.project_id = params[:project_id]
        if params[:is_revision] == '1'
          wp.revision = (wp.revision || 0) + 1
        else
          wp.revision = (wp.revision || 0)
        end
        wp.revised_at = Time.now
        wp.revised_by = current_user.login 
        wp.save

        if params[:is_revision] == '1'
          wr = WikiRevisions.new
          wr.page_id = wp.id
          wr.content = wp.content
          wr.log = wp.log
          wr.revision = wp.revision
          wr.revised_at = wp.revised_at
          wr.revised_by = wp.revised_by
          wr.save
        end
        redirect_to :id => params[:wiki_page][:name] || wp.name, :action => 'show'
      end
    else
      @wiki_page.log = ""
    end
  end

  def revisions
    @wiki_page = WikiPages.find_by_name(params[:id])
    @revisions = WikiRevisions.where(:page_id => @wiki_page.try(:id)).order("revision desc")
  end

  def diff
    pid = params[:id]
    @wiki_page = WikiPages.page_all.find_by_name(pid) 
    if params[:r1]
      @r1 = WikiRevisions.find_by_page_id_and_revision(@wiki_page.id, params[:r1])
    end
    if @r1.nil?
      @r1 = @wiki_page
    end
    if params[:r2]
      @r2 = WikiRevisions.find_by_page_id_and_revision(@wiki_page.id, params[:r2])
    end
    Diffy::Diff.default_format = :html
    @diff_html = Diffy::Diff.new(@r2.content, @r1.content)
  end

  def files
    path = File.join(WIKI_UPLOAD_PATH, '/', params[:project_id], "/*")
    @files = [];
    Dir.glob(path){ |file|
      unless File.directory?(file)
        file_row = {} 
        file_row[:name] = File.basename(file)
        File.open(file, "rb") do |f|
           img = ImageSize.new(f)
           file_row[:format] = img.format
           file_row[:size] = f.stat.size
           file_row[:mtime] = f.stat.mtime
           file_row[:imagesize] = "#{img.w} * #{img.h}" unless img.w.nil?
           file_row[:path] = file
        end
        @files << file_row 
      end
    }
  end

  def delete_files
    unless params[:files].nil?
      params[:files].each do |f|
        begin 
          File.delete(File.join(WIKI_UPLOAD_PATH, params[:project_id], f))
          File.delete(File.join(WIKI_UPLOAD_PATH, params[:project_id], 'small', f))
        rescue 
        end
      end
    end
    redirect_to :action => 'files'
  end

  def web_upload
    if !params[:upload_file].nil?
      #Check and create folder
      project_path = File.join(WIKI_UPLOAD_PATH, params[:project_id])
      unless File.directory?(project_path)
        Dir.mkdir(project_path)
        Dir.mkdir(File.join(project_path, 'small'))
      end
      Dir.chdir(project_path)

      #Upload each file with check exists and size. 
      file_exists = []
      file_size_check = true 
      file_size_total = 0
      params[:upload_file].each do |f|
        file_size_total += f.size
        if f.size > 6*1024*1024#WIKI_MAX_UPLOAD_FILE_SIZE
          file_size_check = false
        end
        if File.exists?(f.original_filename)
          file_exists << f.original_filename
        end
      end

      #Check file size & total size
      foder_size = %x[du -s #{project_path}].scan(/^\d*/)[0].to_i
      if file_size_check == false
        flash[:warning] = t("File size limit ") + number_to_human_size(WIKI_MAX_UPLOAD_FILE_SIZE)
      elsif ((file_size_total+foder_size) > 2*1024*1024)#WIKI_MAX_UPLOAD_TOTAL_SIZE)
        flash[:warning] = t("Total file size limit", 
                            :total => number_to_human_size(WIKI_MAX_UPLOAD_TOTAL_SIZE),
                            :current => number_to_human_size(foder_size),
                            :scope => [:wiki, :message])
      end
      #Check file exists?
      if file_exists.count > 0
        flash[:warning] = t("File exists", :files => file_exists.join(";"), :scope => [:wiki, :message])
      end
      #Upload files
      if flash[:warning].nil? 
        params[:upload_file].each do |f| 
          upload_an_file(f)
        end
      end
    end
    redirect_to :action => 'files' 
  end

protected
  def upload_an_file(uploaded_file)
    save_as = File.join(WIKI_UPLOAD_PATH,
                        params[:project_id] , uploaded_file.original_filename)

    File.open( save_as.to_s, 'w' ) do |file|
      file.write( uploaded_file.read )
      if uploaded_file.content_type.chomp =~ /^image/
        Thread.new do
           convert_to_cache(save_as, 64)
        end
      end
    end
    return true
  end

  def convert_to_cache(image_data, size)
    if File.exists?(image_data)
      image_cache_file = File.join(File.dirname(image_data), 'small', File.basename(image_data))
      if system("/usr/local/bin/convert #{image_data}'[#{size}x#{size}]' #{image_cache_file}") == false
        logger.error("Wiki image convert error. " + 
                     "cmd: 'convert #{image_data}'[#{size}x#{size}]' #{image_cache_file}'")
        return false
      else
        return true
      end
    else
      return false
    end
  end

  def export_html
    export_pages_as_zip("html")
  end

  def export_pdf
    export_pages_as_zip("pdf")
  end

  def export_wiki
    export_pages_as_zip("wiki")
  end

  #remove
  def export
    #export data
    ids = params[:page_id].join(',')
    wps = WikiPages.page_all.where(:project_id => params[:project_id]).where(:id => params[:page_id]) 
    #export folder
    export_base = File.join('/tmp', 'openfoundry-wiki') 
    unless File.directory?(export_base)
      Dir.mkdir(export_base)
    end
    Dir.chdir(export_base)
    export_folder = Time.now.to_f.to_s
    export_files = File.join(export_folder, 'files')
    Dir.mkdir(export_folder)
    Dir.mkdir(export_files)

    #parser init
    parser = Wikitext::Parser.new
    parser.internal_link_prefix = "./"
    parser.img_prefix = "./files/"

    #process each page
    files = []
    wps.each do |wp|
      filename = File.join(export_folder, wp.name)
      wiki_html = parser.parse(wp.content)
      files = files + wiki_html.scan(/files\/([^\.]+\.[a-z]+)" alt=/m)
      File.open(filename, 'w') do |f|
        f.write wiki_html 
      end
    end

    #cp each file
    files = files.uniq
    files.each do |f|
      source = File.join(WIKI_UPLOAD_PATH, params[:project_id], f)
      target = File.join(export_files, f)
      run = "cp #{source} #{target}"
      system(run)
      logger.error run 
    end
    Dir.chdir(export_folder)
    system("tar zcvf ../#{@project.name}.gz ./")
    send_file "../#{@project.name}.gz", :type=>"application/gzip"#, :filename => 'kkk.gz'
  end

  def export_pages_as_zip(file_type)
    html_template = ERB.new(%q{
      <html>
        <head>
          <meta http-equiv="content-type" content="text/html; charset=utf-8" />
          <title><%= wp.name %></title>
        </head>
        <body>
          <%= wiki_html %>
        </body>
      </html>
    }.gsub(/^      /, ''))

    #path init
    file_prefix = "#{@project.name}-#{file_type}-"
    timestamp = Time.now.strftime('%Y-%m-%d-%H-%M-%S')
    file_path = WIKI_EXPORT_PATH.join(file_prefix + timestamp + '.zip')
    tmp_path = "#{file_path}.tmp"
    Dir.mkdir(WIKI_EXPORT_PATH) unless File.directory?(WIKI_EXPORT_PATH)

    #parser init
    parser = Wikitext::Parser.new
    parser.internal_link_prefix = "./"
    parser.img_prefix = "./files/"

    #start zip
    files = []
    Zip::ZipFile.open(tmp_path, Zip::ZipFile::CREATE) do |zip_out|
      ids = params[:page_id].join(',')
      wps = WikiPages.page_all.
                      where(:project_id => params[:project_id]).
                      where(:id => params[:page_id])
      wps.each do |wp|
        zip_out.get_output_stream("#{CGI.escape(wp.name)}.#{file_type}") do |f|
          wiki_html = parser.parse(wp.content)
          files = files + wiki_html.scan(/files\/([^"]*)"/)

          if file_type == 'html'
            wiki_html.gsub!(/href="\.\/[^"]*/){|m| m+'.html'}
            wiki_html = html_template.result(binding)
            f.puts(wiki_html)
          elsif file_type == 'pdf'
            #pdf = WickedPdf.new.pdf_from_string(wiki_html)
            pdf = WickedPdf.new.pdf_from_string('<h1>Hello There!</h1>')
            logger.error wp.name
            logger.error pdf.class
            logger.error "----#{pdf}----"
            f.puts(pdf)
          else
            f.puts(wp.content)
          end
        end
      end
      #zip files
      files.flatten.uniq.each do |f|
        source = WIKI_UPLOAD_PATH.join(params[:project_id], f)
        zip_out.add "files/#{f}", source if File.file?(source)
      end
    end

    #send file
    FileUtils.rm_rf(Dir[WIKI_EXPORT_PATH.join(file_prefix + '*.zip').to_s])
    FileUtils.mv(tmp_path, file_path)
    send_file file_path
  end


  #use RMagick
  def __convert_to_cache(image_data, size)
    if File.exists?(image_data)
      image_cache_file = File.join(File.dirname(image_data), File.basename(image_data, File.extname(image_data)) + '_s' + File.extname(image_data))
      cat = ImageList.new(image_data)
      cat = cat.resize_to_fit(size, size)
      cat.write(image_cache_file)
      logger.error("!!!!!!!!!!!!!!!! magick !!!!!!!!!!!!!!!!!!")
      return
    else
      false
    end
  end

end
