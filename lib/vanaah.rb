require "character"
require "bases"

class Reaping < Style
  def initialize
    super("reaping", 0..1, 0, 1)
  end
  def on_hit!
    {
      #Opponent discards token. If he cannot, [re]gain Divine Rush
      "discard_token" => ->(me, inputs) {
         result = me.opponent.select_and_discard_a_token!
         #select_from_methods(discard_token: me.opponent.token_names).call(me.opponent, inputs)
         me.regain_divine_rush if result.nil?
      }
    }
  end
end

class Judgment < Style
  def initialize
    super("judgment", 0..1, 1, -1)
  end
  # Nearest opponent cannot move (technically on "reveal")
  flag :judgment_paralysis
end

class Paladin < Style
  def initialize
    super("paladin", 0..1, 1, -2)
  end
  def end_of_beat!
    {
      #Move directly to a space adjacent to an opponent
      "teleport_adjacent" => ->(me, inputs) {
        select_from_methods(teleport_to: [me.opponent.position+1, me.opponent.position-1]).call(me, inputs)
      }
    }
  end
  def stun_guard
    3
  end
end

class Glorious < Style
  def initialize
    super("glorious", 0, 2, 0)
  end

  def before_activating!
    {
      #advance 0-1
      "advance" => ->(me, inputs) {
        select_from_methods(advance: [0, 1]).call(me, inputs)
      }
    }
  end

  # Can't hit foes with higher priority
  flag :cannot_hit_higher_priority
end

class Vengeance < Style
  def initialize
    super("vengeance", 0, 2, 0)
  end
  def stun_guard
    4
  end

  # Can't hit foes with lower priority
  flag :cannot_hit_lower_priority
end

class Scythe < Base
  def initialize
    super("scythe", 1..2, 3, 3)
  end
  def before_activating!
    {
      # advance 1
      "advance" => ->(me, inputs) {
        select_from_methods(advance: [1]).call(me, inputs)
      }
    }
  end
  def on_hit!
    {
      # pull 0-1
      "pull" => ->(me, inputs) {
        select_from_methods(pull: [0,1]).call(me, inputs)
      }
    }
  end
end

class DivineRush < Token
  def initialize
    super("divinerush", 0, 2, 2)
  end
  def effect
    "+2 power, +2 priority" 
  end
end

class JudgmentParalysis < Token
  def initialize
    super("judgmentparalysis", 0, 0, 0)
  end
  def effect
    "Cannot move this beat"
  end

  flag :cannot_move
end

class DeathWalksPenalty < Token
  def initialize
    super("deathwalkspenalty", 0, 0, -4)
  end
  def effect
    "-4 priority"
  end
end

class DeathWalks < Finisher
  def initialize
    super("deathwalks", 1..2, 5, 6)
  end
  def on_hit!
    {
      # Stuns opponent, -4 priority next turn
      "stun" => ->(me, inputs) {
        me.opponent.stunned!
        me.death_walks_penalty = DeathWalksPenalty.new
      }
    }
  end
end

class HandOfDivinity < Finisher
  def initialize
    super("handofdivinity", 5, 7, 3)
  end
  def soak
    3
  end
  def on_hit!
    {
      # advance any number of spaces (5 is the max that could ever be advanced)
      "advance" => ->(me, inputs) {
        select_from_methods(advance: 0..5).call(me, inputs)
      }
    }
  end
end

class Vanaah < Character
  attr_reader :token_pool
  attr_accessor :death_walks_penalty
  def self.character_name
    "vanaah"
  end
  def initialize *args
    super

    #set up hand
    @hand << Scythe.new
    @hand += [
      Reaping.new,
      Judgment.new,
      Paladin.new,
      Glorious.new,
      Vengeance.new
    ]
    @token_pool = [
      DivineRush.new
    ]
    @token_bonuses = []
    @token_discard = []
    # For timing the recycle of the death walks -4 priority token
    @death_walks_penalty_timeout = 1
    # For blocking movement
    @judgment_paralysis = JudgmentParalysis.new
  end

  def finishers
    [DeathWalks.new, HandOfDivinity.new]
  end

  def ante_options
    @token_pool.map(&:name) + super
  end

  def ante?(choice)
    return true if super
    @token_pool.any?{ |token| (token.name == choice) }
  end

  def ante!(choice)
    return if super
    if choice == "pass"
      log_me!("passes.")
      return
    end
    token = @token_pool.find{ |token| token.name == choice }
    log_me!("antes #{token.name} #{token.effect}")
    @token_discard << token
    @token_bonuses << token
    @token_pool.delete_if{ |token| token.name == choice }
  end

  def discard_token!(choice)
    token_to_discard = @token_pool.find{ |token| token.name == choice }
    @token_discard << token_to_discard
    log_me!("discards #{token_to_discard.name}")
    @token_pool.delete(token_to_discard)
  end

  def regain_divine_rush
    [@discard1, @discard2, @token_discard].each do |array|
      divine_rush = array.find {|item| item.name == "divinerush"}
      unless divine_rush.nil?
        @token_pool << array.delete(divine_rush)
        log_me!("gains Divine Rush")
        return
      end
    end
  end

  def in_range?
    if (flag?(:cannot_hit_higher_priority) && opponent.priority > priority) || (flag?(:cannot_hit_lower_priority) && opponent.priority < priority)
      log_me!("misses due to #{@style.name}")
      return false
    end
    super
  end

  def blocked_spaces(direct_movement)
    if base_flag?(:judgment_paralysis)
      (0..6).to_a
    else
      []
    end
  end    

  def character_specific_effect_sources  
    @token_discard
  end

  def opponent_effect_sources
    arr = []
    arr << @death_walks_penalty unless @death_walks_penalty.nil?
    arr << @judgment_paralysis if base_flag?(:judgment_paralysis)
    super + arr
  end

  def current_opponent_effects_descriptors
    rtn = []
    rtn << {title: "Death Walks Penalty", content: "-4 priority"} unless @death_walks_penalty.nil?
    rtn << {title: "Judgment Movement Restriction", content: "Cannot move this beat"} if base_flag?(:judgment_paralysis)
    rtn + super
  end

  def token_pool_descriptors
    @token_pool.map(&:descriptor)
  end

  def recycle!
    divine_rush = @discard2.find {|item| item.name == "divinerush"}
    unless divine_rush.nil?
      @token_pool << @discard2.delete(divine_rush)
    end
    super
    # Divine Rush token cycles with cards
    unless @token_discard.empty?
      @discard1 << @token_discard.pop
    end
    @token_bonuses = []
    # Death Walks penalty lasts 1 turn
    if @death_walks_penalty_timeout == 0
      @death_walks_penalty = nil
      @death_walks_penalty_timeout = 1
    end
    @death_walks_penalty_timeout -= 1 unless @death_walks_penalty.nil?
  end
end
