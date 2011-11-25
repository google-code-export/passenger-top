require 'permission_table'

class ApplicationController < ActionController::Base
  protect_from_forgery
  include OpenFoundry::PermissionTable

  protected

  def check_permission
    pass = false
    function_name = PERMISSION_TABLE[controller_name.to_sym][action_name.to_sym]
    begin
      pass =
      if @project
        fpermit?(function_name, @project.id)
      else
        fpermit?(function_name, 0)
      end
    rescue Exception => e
      pass = false
    ensure
      unless(pass)
        flash.now[:warning] = t('you have no permission')#+" [#{function_name} #{e}]!" 
        #redirect_to(request.referer || root_path)
      end
    end
    pass
  end

  def fpermit?(function_name, authorizable_id, authorizable_type = 'Project')
    return true if function_name.to_s == 'allow_all'
    unless current_user.nil?
      if current_user.login == 'wangaguo'
        return true
      end
    end 
    return false
    #Function.function_permit(current_user, function_name, authorizable_id, authorizable_type)
  end
  helper_method :fpermit?

  def utc_to_local(time)
    begin
      Time.zone.utc_to_local(time)
    rescue
      time = ""
    end
  end
  
  def local_to_utc(time)
    begin
      Time.zone.local_to_utc(time.to_time)
    rescue
      time
    end
  end

  def current_user
    u = User.new
    u.login = session["login_name"] || 'guest'
    return u 
  end

  helper_method :current_user
end

class User
  attr_accessor :login
end
