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
        subject.player_locations?.should == {
          0 => 1,
          1 => 5,
        }
      end
    end
    context "from the start of beat 0" do
      before :each do
        subject.input!(0, "sweeping_dash;focused_grasp")
        subject.input!(1, "focused_grasp;sweeping_dash")
      end
      it "asks both players to choose attack pairs" do
        subject.required_input.should == {
          0 => "select_attack_pairs",
          1 => "select_attack_pairs",
        }
      end
      it "does not allow characters to select attacks and styles that are on cooldown" do
          #focused was in the initial discard
          subject.input!(0, "attack:focused_drive")
          subject.required_input[0].should == "select_attack"
      end
      it "allows characters who ante to ante between planning and reveal" do
          #do we need to set the 'nil' or will ruby be OK without it?
          #should 'nil' be something like 'wait' instead?
          #AK: I'm not convinced we even need a :can_ante. The default ante value can just be pass/nil and this can be taken care of with normal 2-pass ante logic
        (subject.game_state[0][:can_ante] == 'true')? @p0ante = "ante"; p0ante = nil
        (subject.game_state[1][:can_ante] == 'true')? @p1ante = "ante"; p1ante = nil
        subject.required_input.should == {
          0 => p0ante,
          1 => p1ante,
        }
      end
      it "reveal happens right after cards are revealed" do
        subject.input!(0, "attack:advancing_drive")
        subject.input!(1, "attack:geomantic_shot")
        subject.gamestate[:events][-1].should == "planning" #this needs to be more specific probably
        subject.input!(0, "ante:pass")
        subject.input!(1, "ante:pass")
        subject.gamestate[:events][-3].should == "ante:nil;nil"
        subject.gamestate[:events][-2].should == "reveal:advancing_drive;geomantic_shot"
      end

      context "after ante/plan" do
        it "clashes if the priority is the same" do
          subject.input!(0, "attack:advancing_drive")
          subject.input!(1, "attack:advancing_drive")
          subject.input!(0, "ante:pass")
          subject.input!(1, "ante:pass")
          subject.gamestate[-1].include?("clash").should == 'true'
        end
        it "start/end of beat effects happen at start/end of beat" do
          #this spec seems too long...it requires a lot of inputs
          subject.input!(0, "attack:trance_burst")
          subject.input!(1, "attack:advancing_drive")
          subject.input!(0, "ante:pass")
          subject.input!(1, "ante:pass")
          subject.game_state(0).beatstart.should == "burst"
          subject.game_state(1).beatstart.should == "advancing"
          subject.game_state(0).beatend.should == "trance"
          subject.game_state(0).beatend.should == nil
          subject.required_input.should == {
            0 => "beatstart:burst"
            1 => nil
          }
          subject.input!(0, "burst:2") # to move back 2 spaces
          subject.game_state[:events][-1].should == "beatstart:1,advancing;0,burst"
          subject.input!(1, "pre_act:drive,2") #advance 2
          subject.required_input.should == {
            0 => "beatend:trance"
            1 => nil
          }
          subject.input!(0, "beatend:trance_earth")
          subject.game_state[:events][-1].should == "beatend:0,trance_earth"
        end
        it "start of beat happens after clashes are resolved"
        it "end of beat effects happen even if you are stunned"
      it "correctly selects active/reactive characters"
      it "before/after activating effects happen at right time for active/reactive characters"
      it "doesn't do before/after activating if you are stunned"
      it "attacks only trigger on hit if in range"
      it "attacks that hit only trigger on damage if they do damage"
      it "attacks that damage stun if they do more damage than opponents stun guard and soak."

      it "soak reduces the ammount of damage you take"


      it "continues to clash until priorities are different, or either player is out of cards"
      end
      it "recycles correctly in the case of a clash"
      
      it "if a player is reduce to < 1 life, they lose"

      it "each match lasts 15 turns, at which point the winner is decided even if both players are > 0 life"
    end
  end
end
