class DataController < ApplicationController
  include DataHelper

  before_filter :collect_games

  def games_kd
    games = @games.collect do |g|
      p = g['Players'].find{|p| p['Gamertag'] =~ gamertagregex}
      {
        :x => Time.parse(g['EndDateUtc']).to_i * 1000,
        :y => p['Kills'] - p['Deaths'],
        :marker => {:radius => [[p['Kills'] + p['Deaths'], 0].max, 100].min * (0.2) + 1 }
      }
    end
    render :json => [{:name => 'Spread by match', :data => games, :type => 'scatter'}]
  end

  def kd
    cumulative = 0
    data_spread = @games.collect do |g|
      p = g['Players'].find{|p| p['Gamertag'] =~ gamertagregex}
      cumulative += p['Kills'] - p['Deaths']
      {:x => Time.parse(g['EndDateUtc']).to_i * 1000, :y => cumulative}
    end

    render :json => [{:name => 'Spread (cumulative)', :data => data_spread, :type => 'line'}]
  end

  def games_kdr
    games = @games.collect do |g|
      p = g['Players'].find{|p| p['Gamertag'] =~ gamertagregex}
      {
        :x => Time.parse(g['EndDateUtc']).to_i * 1000,
        :y => p['Deaths'] == 0 ? -1 : p['Kills'].to_f / p['Deaths'], # TODO: fix div by zero hack
        :marker => {:radius => [[p['Kills'] + p['Deaths'], 0].max, 100].min * (0.2) + 1 }
      }
    end
    render :json => [{:name => "KDR by match", :data => games, :type => 'scatter'}]
  end

  def kdr
    cumulative_by_split = {}
    series_data_by_split = {}
    @games.each do |g|
      p = g['Players'].find{|p| p['Gamertag'] =~ gamertagregex}
      split_key_name = params[:split].present? ? g[params[:split]] : 'Overall'

      cumulative_by_split[split_key_name] ||= {k: 0, d: 0}
      cumulative = cumulative_by_split[split_key_name]
      cumulative[:k] += p['Kills']
      cumulative[:d] += p['Deaths']

      series_data_by_split[split_key_name] ||= []
      series_data_by_split[split_key_name] << {
        :x => Time.parse(g['EndDateUtc']).to_i * 1000,
        :y => cumulative[:d] == 0 ? nil : (cumulative[:k].to_f / cumulative[:d])
      }
    end
    j = series_data_by_split.collect do |k, v|
      {:name => "#{k}", :data => v, :type => 'line'}
    end
    render :json => j
  end

end