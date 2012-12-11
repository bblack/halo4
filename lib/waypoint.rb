class Waypoint
  include Mongo

  @@mc = MongoClient.new('localhost', 27017)

  def self.mongo_client
    @@mc
  end

  class Halo4
    @@token = "v2=i6g4eAPQXxHqagAJLT6v9KEtBcQgKrP9Uh47H4Cw02heUY8p7FLlSKByi76rOkiR4GMZHa9peVDvMnPYUnxupOpSTSe5PQ4s_Ic1uzALcTogMKCXqUjNMWLtYeXF7jy-OQFjpE8ck-HY-xPGALWVoMRmVKEMG36q59ur0fCMPrWWJsXG6qF07VaF5ASAmagBK_AEHl0Xqchb285yX2_rsg4VTtZXvjRz2shYAUOHiNaeAlYvQZYEnVltjBXRvPPi98MYxerY_cAyW4T7e_5TQzn3JKjQtlp7T139SiUJyes5po2fMOEPs-E4LjlNkZ7JgZSLoYGfIjRe7i6v70n9-e5_2ZzfJ-4Nvb5oHRytvQt_DbVwQNRle_ya0qmztGmSNB0tgXL45ZRM8ZpCjhLBEdeRBVZPHLE"
    @@db = Waypoint.mongo_client.db("halo4-#{Rails.env}")
    
    def self.token
      @@token
    end

    def self.db
      @@db
    end

    class GamesFetcher
      @queue = :everything

      def self.perform(gamertag)
        last_index = 0 # Remember, this is no. of games before latest
        batch_size = 100
        games = []

        while true
          res = Typhoeus.get(
            "https://stats.svc.halowaypoint.com/en-us/players/#{gamertag}/h4/matches",
            {
              :params => {:gamemodeid => 3, :count => batch_size, :startat => last_index},
              :headers => {:Accept => 'application/json', 'X-343-Authorization-Spartan' => Waypoint::Halo4.token}
            }
          )
          raise StandardError.new("Got status #{res.code}") if not res.success?
          o = JSON.parse(res.body)
          last_index += batch_size # If new games are added while we're doing this, then we get overlap
          games += o['Games']
          break if o['Games'].count < batch_size
        end

        # mongo doesn't allow "$" in key
        games.each {|g| g['dollarType'] = g['$type']; g.delete('$type')}

        games.each do |g|
          Waypoint::Halo4.db['games'].update(
            {:Id => g['Id']},
            g,
            {:upsert => true}
          )
        end

        games
      end
    end

    class GameDetailsFetcher
      @queue = :everything

      def self.perform(game_id)
        res = Typhoeus.get(
          "https://stats.svc.halowaypoint.com/en-us/h4/matches/#{game_id}",
          {:headers => {:Accept => 'application/json', 'X-343-Authorization-Spartan' => Waypoint::Halo4.token}}
        )
        raise StandardError.new("Got status #{res.code}") if not res.success?
        o = JSON.parse(res.body)
        Waypoint::Halo4.db['games'].update(
          {:Id => o['Id']},
          o,
          {:upsert => true}
        )

        o
      end
    end

  end
end