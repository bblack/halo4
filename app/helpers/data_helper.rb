module DataHelper

  def collect_games
    @games = Waypoint::Halo4.db['games']
      .find({'Players.Gamertag' => gamertagregex})
      .to_a
      .sort{|g,h| g['EndDateUtc'] <=> h['EndDateUtc']}
  end

  def gamertagregex
    Regexp.new(params[:gamertag], Regexp::IGNORECASE)
  end

end