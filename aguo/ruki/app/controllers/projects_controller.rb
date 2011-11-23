class ProjectsController < ApplicationController
  def index
    @projects = Projects.all
  end

  def login
    if request.post?
      if params[:submit_wangaguo]
        session["login_name"] = "wangaguo"
      elsif params[:submit_shawn]
        session["login_name"] = "shawn"
      else
        session["login_name"] = "guest"
      end
      redirect_to projects_path
    end
  end

  def lang
    if params[:lang] == 'en'
      session["wiki_lang"] = 'en'
    else
      session["wiki_lang"] = 'zh_TW'
    end
    redirect_to projects_path 
  end
end
