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
  game = GAMES[params[:game_id]]
  #Return any answer for the given input
  game.input!(params['player_id'], params['action'])
  ::MultiJson.dump({
    'game_state' => game.game_state,
    'required_input' => game.required_input[params['player_id'].to_i]
  })
end
