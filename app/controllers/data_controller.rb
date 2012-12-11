class DataController < ApplicationController
  def kd
    # mongo queries by string are case sensitive
    gamertagregex = Regexp.new(params[:gamertag], Regexp::IGNORECASE)

    games = Waypoint::Halo4.db['games']
      .find({'Players.Gamertag' => gamertagregex}, {:limit => 200})
      .sort(:EndDateUtc)
      .collect do |g|
        p = g['Players'].find{|p| p['Gamertag'] =~ gamertagregex}
        {
          :x => Time.parse(g['EndDateUtc']).to_i * 1000,
          :y => p['Kills'] - p['Deaths']
        }
      end
    runningspread = 0
    runningspread = games.collect do |g|
      runningspread += g[:y]
      {:x => g[:x], :y => runningspread}
    end
    render :json => [
      {:name => 'Spread by match', :data => games, :type => 'scatter'},
      {:name => 'Cumulative spread', :data => runningspread, :type => 'line', :yAxis => 1}]
  end
end