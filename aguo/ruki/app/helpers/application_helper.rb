module ApplicationHelper
  def language_select(name, selected, options = {})
    language_options = options_for_select([["English", "en"],["繁體中文", "zh_TW"]], selected)
    select_tag name, language_options, options
  end

  def tz_date(time_at)
    begin
      time = Time.zone.utc_to_local(time_at.utc)
      time.strftime("%Y-%m-%d")
    rescue
      ""
    end
  end
  
  def tz_datetime(time_at)
    begin
      time = Time.zone.utc_to_local(time_at.utc)
      time.strftime("%Y-%m-%d %H:%M") + ' ' + Time.zone.formatted_offset
    rescue
      ""
    end
  end

end
