class DataController < ApplicationController
  include DataHelper

  before_filter :collect_games

  def kd
    games = @games.collect do |g|
      p = g['Players'].find{|p| p['Gamertag'] =~ gamertagregex}
      {
        :x => Time.parse(g['EndDateUtc']).to_i * 1000,
        :y => p['Kills'] - p['Deaths'],
        :marker => {:radius => [[p['Kills'] + p['Deaths'], 0].max, 100].min * (0.1) + 1 }
      }
    end

    cumulative = 0
    data_spread = games.collect do |g|
      cumulative += g[:y]
      {:x => g[:x], :y => cumulative}
    end

    render :json => [
      {:name => 'Spread by match', :data => games, :type => 'scatter'},
      {:name => 'Spread (cumulative)', :data => data_spread, :type => 'line', :yAxis => 1}]
  end

  def kdr
    games = @games.collect do |g|
      p = g['Players'].find{|p| p['Gamertag'] =~ gamertagregex}
      {
        :x => Time.parse(g['EndDateUtc']).to_i * 1000,
        :y => p['Deaths'] == 0 ? -1 : p['Kills'].to_f / p['Deaths'], # TODO: fix div by zero hack
        :marker => {:radius => [[p['Kills'] + p['Deaths'], 0].max, 100].min * (0.1) + 1 }
      }
    end

    cumulative = {k: 0, d: 0}
    data = @games.collect do |g|
      p = g['Players'].find{|p| p['Gamertag'] =~ gamertagregex}
      cumulative[:k] += p['Kills']
      cumulative[:d] += p['Deaths']
      {
        :x => Time.parse(g['EndDateUtc']).to_i * 1000,
        :y => cumulative[:d] == 0 ? nil : (cumulative[:k].to_f / cumulative[:d])
      }
    end

    render :json => [
      {:name => "KDR by match", :data => games, :type => 'scatter'},
      {:name => "KDR (cumulative)", :data => data, :type => 'line', :yAxis => 1}]
  end

end