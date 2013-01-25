require 'sinatra'
require 'json'
require_relative File.join("..", "lib", "game")

game_list[] = Hash.new

get '/game/:game_id/:player' do
  unless game_list.has_key?(game_:id)
    game_list[:game_id] = game.new
  end
  haml :game_layout
end

put '/game/:game_id/:player_id/:input' do
  #Return any answer for the given input
  :game_id.input!(:player_id, :input)[:player_id]
end
