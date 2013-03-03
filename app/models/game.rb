require 'game_play'
class Game < ActiveRecord::Base
  attr_accessible :inputs
  serialize :inputs

  def play
    GamePlay.new(inputs)
  end
  def input_and_save!(id, action)
    g = GamePlay.new(inputs)
    g.input!(id, action)
    self.inputs = g.valid_inputs
    save!
  end
end
