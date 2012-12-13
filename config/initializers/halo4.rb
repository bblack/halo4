require 'waypoint'

Waypoint::Halo4.db['games'].ensure_index([['Players.Gamertag', Mongo::ASCENDING]])
Waypoint::Halo4.db['games'].ensure_index([['Id', Mongo::ASCENDING]], :unique => true)