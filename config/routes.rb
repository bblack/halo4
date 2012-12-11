Halo4::Application.routes.draw do
  get '/data/kd/:gamertag' => 'data#kd'

  get '/charts/kd/:gamertag' => 'charts#kd'
end
