class ReportController < ApplicationController

  def view
    @site = Site.find_by name_url: params[:site_name_url]
    @guides = Guide.where({:is_active => true})
  end

  def get_fish_score_color(value)
    case value
      when 0
        return '#D11919'
      when 1
        return '#D63333'
      when 2
        return '#EE5233'
      when 3
        return '#FF8533'
      when 4
        return '#FFDB4D'
      when 5
        return '#D3D129'
      when 6
        return '#A3D119'
      when 7
        return '#7CD62C'
      when 8
        return '#42CC29'
      when 9
        return '#19A319'
      when 10
        return '#1F7A1F'
      else
        return '#D3D129'
      end
  end

  helper_method :get_fish_score_color

end