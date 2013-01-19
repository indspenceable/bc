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
      it "puts the players in their starting locations" do
        subject.game_state[:players][0][:location].should == 1
        subject.game_state[:players][1][:location].should == 5
      end
    end
    context "from the start of beat 0" do
      before :each do
        subject.input!(0, "trance_dash;focused_grasp")
        subject.input!(1, "focused_grasp;trance_dash")
      end
      it "asks both players to choose attack pairs" do
        subject.required_input.should == {
          0 => "select_attack_pairs",
          1 => "select_attack_pairs",
        }
      end
      it "does not allow characters to select attacks and styles that are on cooldown" do
          #focused was in the initial discard
          expect{ subject.input!(0, "attack:focused_drive") }.to raise_error
          subject.required_input[0].should == "select_attack"
      end
      it "allows characters who ante to ante between planning and reveal" do
          #do we need to set the 'nil' or will ruby be OK without it?
          #should 'nil' be something like 'wait' instead?
        (subject.game_state[0][:can_ante] == 'true')? @p0ante = "ante" :  @p0ante = nil
        (subject.game_state[1][:can_ante] == 'true')? @p1ante = "ante" :  @p1ante = nil
        subject.required_input.should == {
          0 => @p0ante,
          1 => @p1ante,
        }
      end
      it "reveal happens right after cards are revealed" do
        subject.input!(0, "attack:advancing_drive")
        subject.input!(1, "attack:geomantic_shot")
        subject.game_state[:events][-1].should == "planning" #this needs to be more specific probably
        subject.input!(0, "ante:done")
        subject.input!(1, "ante:done")
        subject.game_state[:events][-2].should == "ante:nil;nil"
        subject.game_state[:events][-1].should == "reveal:advancing_drive;geomantic_shot"
      end
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
