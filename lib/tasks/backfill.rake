task :backfill => :environment do
  Subscription.all.each do |s|
    Resque.enqueue(Waypoint::Halo4::GamesFetcher, s.gamertag)
  end
end