class Waypoint
  include Mongo

  @@mc = MongoClient.new('localhost', 27017)
  @@config = YAML.load_file(File.join(Rails.root, 'config', 'waypoint.yml'))[Rails.env]

  def self.config
    @@config
  end

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
    @@redis = Redis::Namespace.new("halo4-#{Rails.env}")
    @@db = Waypoint.mongo_client.db("halo4-#{Rails.env}")
    
    def self.new_token
      res = Typhoeus.get("https://app.halowaypoint.com/oauth/signin?returnUrl=https%3A%2F%2Fapp.halowaypoint.com%2Fen-us%2FHalo4")
      res = Typhoeus.get(URI.encode(res.headers['Location']))
      nexturl = /urlPost\:'(.*?)'/.match(res.body)[1]
      nextheaders = {
        'PPFT' => /sFTTag\:'\<input.*?value=\"(.*?)\"/.match(res.body)[1],
        'PPSX' => /F\:'(.*?)'/.match(res.body)[1],
        'i3' => 10000, # js-calc'd time that the user spent on the login page in ms
        'login' => Waypoint.config['login'],
        'passwd' => Waypoint.config['passwd'],
        'LoginOptions' => 3,
        'NewUser' => 1,
        'type' => 11,
        'm1' => 1440,
        'm2' => 900,
        'm3' => 0,
        'i12' => 1,
        'i17' => 0,
        'i18' => '__MobileLogin|1,'
      }
      res = Typhoeus.post(nexturl, :body => nextheaders)
      res = Typhoeus.get(URI.encode(res.headers['Location']))
      webauth = /WebAuth=(.*?);/.match(res.headers['Set-Cookie'])[0]
      res = Typhoeus.get(URI.encode(res.headers['Location']), :headers => {'Cookie' => webauth})
      wlid_token = /access_token\:'(.*?)'/.match(res.body)[1]
      res = Typhoeus.get("https://settings.svc.halowaypoint.com/RegisterClientService.svc/spartantoken/wlid", :headers => {'X-343-Authorization-WLID' => "v1=#{wlid_token}"})
      spartan_token = res.headers['X-343-Authorization-Spartan']
    end

    def self.token
      @@redis.get('token')
    end

    def self.token=(x)
      @@redis.set('token', x)
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