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
    @@token = "v2=MbabGhWmFgUwAR4LXslNTRCBmYeeQNlk5VxJouVXzV3yeCZ5JqMUb6ruTYpnELLw7JptifzvIkEs2EsUsn8sGz8D_s2BpIElbrPxInCFnp4hleIjxVvAcVnc6HZfOAHJB5RT0GIpln_CgfV2kULyuYBpUTKx_6LPWuUvSw3ZJR907uZghBUis5YwTkewbVU8zrF44xiJkRgRQLCAOvcnlTTG3tNLaMCt3WWuRQK9tXzuqw30zSs3MmHhmQNuyGmA5eNSAKC-ugfNAiYjmghaDDod9D0bXK3PTJ-qcOptU23o3z8uCbTgkC04q9wsbJzJL4j1jnh-O3jRpgulRXD9yLxx5Y8fCvpzXwXIDVm4tODldh-gy3LUbWVPc-sONkoislbN7ombi84iln_rQaRA_tIDorr8inc"
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
        games.each {|g| Waypoint.mongoify(g)}

        games.each do |g|
          Waypoint::Halo4.db['games'].update(
            {:Id => g['Id']},
            g,
            {:upsert => true}
          )
          Resque.enqueue(Waypoint::Halo4::GameDetailsFetcher, g['Id'])
        end

        games
      end
    end

    class GameDetailsFetcher
      @queue = :everything

      def self.perform(game_id)
        # break it here if we already have this game?
        # pass an overwrite flag to force fetching it?
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