require 'sinatra'
require 'multi_json'
require 'haml'
require_relative File.join("lib", "game")

# Make games if needed.
GAMES = Hash.new{ |h,k| h[k] = Game.new }

get '/games/:game_id/:player_id' do
  @game_id = params[:game_id]
  @game = GAMES[params[:game_id]]
  @player_id = params[:player_id].to_i
  @starting_configuration = ::MultiJson.dump({
    'gameState' => @game.game_state,
    'requiredInput' => @game.required_input[@player_id]
  })
  haml :game
end

get '/ping/:game_id/' do
  game = GAMES[params[:game_id]]
  #Return any answer for the given input
  ::MultiJson.dump({
    'gameState' => game.game_state,
    'requiredInput' => game.required_input[params['player_id'].to_i]
  })
end

post '/games/:game_id/' do
  game = GAMES[params[:game_id]]
  #Return any answer for the given input
  game.input!(params['player_id'], params['action'])
  ::MultiJson.dump({
    'gameState' => game.game_state,
    'requiredInput' => game.required_input[params['player_id'].to_i]
  })
end
