class Waypoint
  include Mongo

  @@mc = MongoClient.new('localhost', 27017)

  def self.mongo_client
    @@mc
  end

  def self.mongoify(object)
    # todo: there should be a Waypoint::fetch that does the GET,
    # and recursively dollar-cleans keys
    if object.class == Hash
      object.keys.select{|k| k.include? '$'}.each do |k|
        object[k.gsub('$', 'dollar')] = object[k]
        object.delete(k)
      end
      object.each {|k,v| self.mongoify(v)}
    elsif object.class == Array
      object.each {|e| self.mongoify(e)}
    end
  end

  class Halo4
    @@token = "v2=hGx4uNdBB1Tr27hTGzVI-EA49BnkV3VuUvQ9Bqy57XYny9AWsV6fIV41q4k_D2HzAMzyLZHe9apHBemp5VNL7NqiLT1zgbg82IzD-5juRCKJd6NC41u5RnwM1WXzjOeIxI2uZWTpMnMEjjTL-vTsFtWy9OcilXdLIBmKrGfblZAw7raevvB-1w0Nh1gBa57YhYyPHgxT8KvTQntjlV0pe1egn1pB3YcOPvzp07geqHZFlXFYeXm2AoRgXNnON2lxavoo-IYJIgZLTyMUzo__I4oWOkQ0Ml8um0XrNMjEx6PAjFVosLTHVFeRlAYDteza9ivzdv9Kf5lPwLHKzE1iDDC_LA0sQusou0KaBcpWmcGAlZek5flLxMI2S9iv_M0GndSsGSiUjsnHtnQFTCKCHmrs555OWz4"
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
          # todo: check exactly which games are not in db and only q up those
          games += o['Games']
          break if o['Games'].count < batch_size
          break if Waypoint::Halo4.db['games'].find_one({:Id => o['Games'].last['Id']}) # last is earliest
        end

        # mongo doesn't allow "$" in key
        games.each {|g| Waypoint.mongoify(g)}

        games.each do |g|
          begin
            Waypoint::Halo4.db['games'].insert(g)
            Resque.enqueue(Waypoint::Halo4::GameDetailsFetcher, g['Id'])
          rescue Mongo::OperationFailure => ex
            # if dup id exists on insert, details fetcher won't be Q'd
            raise unless ex.error_code == 11000
          end
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
        o = JSON.parse(res.body)['Game']
        Waypoint.mongoify(o)
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