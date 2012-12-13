Halo4::Application.routes.draw do
  get '/data/kd/:gamertag' => 'data#kd'
  get '/data/kdr/:gamertag' => 'data#kdr'

  get '/charts/kd/:gamertag' => 'charts#kd'
  get '/charts/kdr/:gamertag' => 'charts#kdr'
end
