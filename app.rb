require 'sinatra'
require 'multi_json'
require 'haml'
require_relative File.join("lib", "game")

# Make games if needed.
GAMES = Hash.new{ |h,k| h[k] = Game.new }

get '/games/:game_id/:player_id' do
  @game_id = params[:game_id]
  @game = GAMES[params[:game_id]]
  @player_id = params[:player_id]
  haml :game
end

post '/games/:game_id/' do
  #Return any answer for the given input
  GAMES[params[:game_id]].input!(params['player_id'], params['action'])
  ::MultiJson.dump(GAMES[params[:game_id]].game_state)
end
