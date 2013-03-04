require 'spec_helper'

describe Game do
  describe "#input_and_save!" do
    it "should save new inputs" do
      g_id = Game.create(inputs: []).id
      Game.find(g_id).input_and_save!(0, 'hikaru')
      Game.find(g_id).input_and_save!(1, 'cadenza')
      Game.find(g_id).reload.inputs.should == [[0, 'hikaru'], [1, 'cadenza']]
    end
  end
  describe '#set_active' do
    game = Game.create(inputs: [])
    game.active = false
    game.save
    game.active.should == true
  end
end
