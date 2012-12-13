class DataController < ApplicationController
  include DataHelper

  before_filter :collect_games

  def kd
    games = @games.collect do |g|
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

  def kdr
    totalk = 0
    totald = 0
    games = @games.collect do |g|
      p = g['Players'].find{|p| p['Gamertag'] =~ gamertagregex}
      totalk += p['Kills']
      totald += p['Deaths']
      {
        :x => Time.parse(g['EndDateUtc']).to_i * 1000,
        :y => totald == 0 ? 0 : (totalk.to_f / totald)
      }
    end

    render :json => games
  end

end