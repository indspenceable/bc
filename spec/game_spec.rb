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
      subject.input!(0, "hikaru")
      subject.input!(1, "hikaru")
    end
    context "setup" do
      it "asks both players to choose discards" do
        subject.required_input.should == {
        0 => "select_discards",
        1 => "select_discards"
        }
      end
      it "puts the players in their starting locations" do
        subject.game_state[:players][0][:location].should == 1
        subject.game_state[:players][1][:location].should == 5
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
        expect{ subject.input!(0, "attack:focused_drive") }.to raise_error
      end
      it "allows characters who ante to ante between planning and reveal" do
        #attack
        subject.input!(0, "trance_drive")
        subject.input!(1, "trance_drive")
        subject.required_input.should == {
          #for now, player 0 will always ante first
          0 => "ante",
          # 1 => "ante",
        }
      end
      it "skips the ante phase if no players can ante" do
        subject
      end
      it "reveal happens right after cards are revealed" do
        #attack
        subject.input!(0, "advancing_drive")
        subject.input!(1, "geomantic_shot")
        #ante
        subject.input!(0, "pass")
        subject.input!(1, "pass")
#        puts subject.game_state[:events][-5..-1]
        subject.game_state[:events][-3].should == "ante:nil;nil"
        subject.game_state[:events][-2].should == "reveal:advancing_drive;geomantic_shot"
      end

      context "after ante/plan" do
        context "regarding clashes" do
          before :each do
            #attack
            subject.input!(0, "advancing_strike")
            subject.input!(1, "trance_drive")
            #ante
            subject.input!(0, "pass")
            subject.input!(1, "pass")
          end
          it "clashes if the priority is the same" do
            subject.game_state[:events][-1].include?("Clash").should == true
            puts subject.game_state[:events][-1]
            subject.required_input.should == {
              0 => "select_new_base",
              1 => "select_new_base"
            }
          end
          it "start of beat happens after clashes are resolved" do
            subject.input!(0, "shot")
            subject.input!(1, "burst")
            subject.game_state[:events][-1].include?("Start of beat").should == 'true'
            end
          it "continues to clash until priorities are different" do
            subject.input!(0, "burst")
            subject.input!(1, "shot")
            subject.game_state[:events][-1].include?("Clash").should == 'true'
            subject.required_input.should == {
              0 => "select_new_base",
              1 => "select_new_base"
            }
            subject.input!(0, "drive")
            subject.input!(1, "strike")
            subject.game_state[:events][-1].include?("Start of beat").should == 'true'
          end
          it "recycles correctly in the case of a clash" do
            subject.input!(0, "drive")
            subject.input!(1, "strike")
            #Drive before activate
            subject.input!(0, "2")
            #Trance End of Beat
            subject.input!(1, "")
            #do these need to be strike/drive objects or are we just doing strings?
            subject.game_state[:players][0][:available_bases].include?("drive").should == 'false'
            subject.game_state[:players][0][:available_bases].include?("strike").should == 'true'
            subject.game_state[:players][1][:available_bases].include?("strike").should == 'false'
            subject.game_state[:players][1][:available_bases].include?("drive").should == 'true'
          end
          it "continues to clash until either player is out of cards"            
        end
        it "start/end of beat effects happen at start/end of beat" do
          #attack pairs
          subject.input!(0, "trance_burst")
          subject.input!(1, "advancing_drive")
          #ante
          subject.input!(0, "pass")
          subject.input!(1, "pass")
          subject.game_state(0).beatstart.should == "burst"
          subject.game_state(1).beatstart.should == "advancing"
          subject.game_state(0).beatend.should == "trance"
          subject.game_state(0).beatend.should == nil
          subject.required_input.should == {
            0 => "beatstart:burst",
            1 => nil
          }
          subject.input!(0, "2") # to move back 2 spaces during Start of Beat
          subject.game_state[:events][-1].should == "beatstart:1,advancing;0,burst"
          subject.input!(1, "2") #Drive: advance 2 during Before Activation
          subject.required_input.should == {
            0 => "beatend:trance",
            1 => nil
          }
          subject.input!(0, "earth")
          subject.game_state[:events][-1].should == "beatend:0,trance_earth"
        end

        context "regarding priority" do
          before :each do
          #attack pairs
          subject.input!(0, "trance_burst")
          subject.input!(1, "advancing_drive")
          #ante
          subject.input!(0, "pass")
          subject.input!(1, "pass")
          end
          it "correctly selects active/reactive characters" do
            subject.active_player.should == 1
          end
          it "before/after activating effects happen at right time for active/reactive characters"
        end
      it "attacks only trigger on hit if in range"
      it "attacks that hit only trigger on damage if they do damage"

      it "soak reduces the ammount of damage you take"
        # TODO Hikaru does not have any soak
      
      it "if a player is reduce to < 1 life, they lose"

        it "each match lasts 15 turns, at which point the winner is decided even if both players are > 0 life"
      end
    end
    context "regarding damaging and stun effects" do
      before :each do
        #discard
        subject.input!(0, "sweeping_dash;focused_grasp")
        subject.input!(1, "focused_grasp;sweeping_dash")
        subject.player_locations = {
          0 => 1,
          1 => 4 
        }
        #attacks
        subject.input!(0, "advancing_palmstrike")
        subject.input!(1, "trance_drive")
        #ante
        subject.input!(0, "pass")
        subject.input!(1, "pass")
      end
      it "attacks that damage stun if they do more damage than opponents stun guard and soak." do
        subject.game_state[:players][1][:stunned].should == 'true'
      end
      it "doesn't do before/after activating if you are stunned" do
        #no actions for player one should happen
        subject.game_state[:events][-1,-3].include?("1").should == 'false'
      end
      it "end of beat effects happen even if you are stunned" do
        #Should prompt user for token selection from Trance style
        subject.required_input.should == {
          0 => nil,
          1 => "trance"
        }
      end
    end
  end
end
