class DataController < ApplicationController
  def kd
    games = Waypoint::Halo4.db['games']
      .find({'Players.Gamertag' => params[:gamertag]}, {:limit => 200})
      .sort(:EndDateUtc)
      .collect do |g|
        p = g['Players'].find{|p| p['Gamertag'] == params[:gamertag]}
        {
          :x => Time.parse(g['EndDateUtc']).to_i * 1000,
          :y => p['Kills'] - p['Deaths']
        }
      end
    render :json => games
  end
end