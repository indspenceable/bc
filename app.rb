require 'sinatra'
require 'multi_json'
require 'haml'
require 'data_mapper'
require_relative File.join("lib", "game")

class GameRecord
  include DataMapper::Resource
  property :id, Serial
  property :serialized_inputs, String
end
configure do
  DataMapper.setup(:default, (ENV["DATABASE_URL"] || "sqlite3:///#{Dir.pwd}/development.sqlite3"))
  DataMapper.auto_upgrade!
end

# Make games if needed.
def load_game(game_id)
  game = GameRecord.get(Integer(game_id))
  if game
    Game.new(YAML.load(game.serialized_inputs))
  else
    Game.new()
  end
end
def save_game!(game_id, g)
  game = GameRecord.get(Integer(game_id))
  if game
    game.update!(:serialized_inputs => YAML.dump(g.valid_inputs))
  else
    GameRecord.create(id: Integer(game_id), :serialized_inputs => YAML.dump(g.valid_inputs)).save!
  end
end


get '/games/:game_id/:player_id' do
  @game_id = params[:game_id]
  @game = load_game(params[:game_id])
  @player_id = params[:player_id].to_i
  @starting_configuration = ::MultiJson.dump({
    'gameState' => @game.game_state,
    'requiredInput' => @game.required_input[@player_id]
  })
  haml :game
end

get '/ping/:game_id/' do
  game = load_game(params[:game_id])
  # Return any answer for the given input
  ::MultiJson.dump({
    'gameState' => game.game_state,
    'requiredInput' => game.required_input[params['player_id'].to_i]
  })
end

post '/games/:game_id/' do
  game = load_game(params[:game_id])
  #Return any answer for the given input
  game.input!(params['player_id'], params['action'])
  save_game!(params[:game_id], game)
  ::MultiJson.dump({
    'gameState' => game.game_state,
    'requiredInput' => game.required_input[params['player_id'].to_i]
  })
end

# static assets
get '/:file' do
  File.read(File.join('public', params[:file]))
end
