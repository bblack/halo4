class ChartsController < ApplicationController
  def kdr
    render(
      '_chart',
      :locals => {
        :element_id => "kdrchart",
        :data_url => "/data/kdr/#{params[:gamertag]}?#{params.slice(:split).to_query}",
        :title => "KDR: #{params[:gamertag]}"
      }
    )
  end

  def kd
    render(
      '_chart',
      :locals => {
        :element_id => "kdchart",
        :data_url => "/data/kd/#{params[:gamertag]}?#{params.slice(:split).to_query}",
        :title => "K-D Spread: #{params[:gamertag]}"
      }
    )
  end
end