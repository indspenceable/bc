require 'spec_helper'

File.open('spec/saved_games.yml', 'r') do |f|
  GAME_RECORDS = YAML::load( f.read )
end

describe GamePlay do
  GAME_RECORDS.each do |g|
    it "Should successfully play this game." do
      starting_player, orders =  g
      Game
      gp = GamePlay.new(starting_player, %w(a b))
      orders.each do |pl, order|
        gp.input!(pl, order)
        [nil, 0, 1].each{|i| gp.game_state(i)}
      end
    end
  end
end
