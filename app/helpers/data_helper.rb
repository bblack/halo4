module DataHelper

  def collect_games
    filter = {'Players.Gamertag' => gamertagregex}
    filter['EndDateUtc'] ||= {} and filter['EndDateUtc']['$gte'] = params[:since] if params[:since].present?
    filter['EndDateUtc'] ||= {} and filter['EndDateUtc']['$lte'] = params[:until] if params[:until].present?

    @games = Waypoint::Halo4.db['games']
      .find(filter)
      .to_a
      .sort{|g,h| g['EndDateUtc'] <=> h['EndDateUtc']}
  end

  def gamertagregex
    Regexp.new(params[:gamertag], Regexp::IGNORECASE)
  end

end