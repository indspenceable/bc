require 'spec_helper'
require_relative File.join("..", "lib", "game")

describe Game do
  subject { Game.new }
  context "A new game" do
    it "asks both players to select their characters" do
      subject.required_input.should == {
        0 => "select_character",
        1 => "select_character",
      }
    end
    it "doesn't reveal character choices until both players have selected" do
      subject.input!(0, "hikaru")
      subject.required_input.should == {
        1 => "select_character"
      }
      subject.game_state[:events].should be_empty
    end
  end
  context "playing a game with characters selected" do
    before :each do
      # these should probably be test characters?
      subject.input!(0, "hikaru")
      subject.input!(1, "hikaru")
    end
    context "setup" do
      it "asks both players to choose discards" do
        subject.required_input.should == {
        0 => "select_discards",
        1 => "select_discards",
      }
      end
      it "blah blah blah more tests?"
    end
    context "from the start of beat 0" do
      before :each do
        # choose discards here
      end
      it "asks both players to choose attack pairs, and reveals them"
      it "allows characters who ante to ante between planning and reveal"

      it "reveal happens right after cards are revealed"

      it "start/end of beat effects happen at start/end of beat"
      it "start of beat happens after clashes are resolved"
      it "end of beat effects happen even if you are stunned"

      it "correctly selects active/reactive characters"
      it "before/after activating effects happen at right time for active/reactive characters"
      it "doesn't do before/after activating if you are stunned"
      it "attacks only trigger on hit if in range"
      it "attacks that hit only trigger on damage if they do damage"
      it "attacks that damage stun if they do more damage than opponents stun guard and soak."

      it "soak reduces the ammount of damage you take"

      it "clashes if the priority is the same"
      it "continues to clash until priorities are different, or either player is out of cards"
      it "recycles correctly in the case of a clash"

      it "if a player is reduce to < 1 life, they lose"
      it "each match lasts 15 turns, at which point the winner is decided even if both players are > 0 life"
    end
  end
end
