require 'yaml'
require './config/environment'

desc "Dumps inactive games to a file for specs to test against."
task :dump_games do
  total = []
  Game.inactive.each do |game|
    total << [game.starting_player, game.inputs]
  end
  File.open('spec/saved_games.yml', 'w') do |out|
    YAML.dump(total, out)
  end
end
