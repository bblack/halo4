# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

require 'resque/server'

Resque::Server.use Rack::Auth::Basic do |username, password|
  true
  #username == '' && password == ''
end

run Rack::URLMap.new(
  '/' => Halo4::Application,
  '/resque' => Resque::Server.new,
)
