require "character"
require "bases"

class Hunters < Style
  def initialize
    super("hunters", 0, 1, 0)
  end
  def reveal(me)
    me.hunters_bonus_if_on_or_adacent_to_trap!
  end
end

class Teleport < Style
  def initialize
    super("teleport", 0..2, 1, -4)
  end
  def reveal!(me)
    me.trap_blocks_ranged_attacks!
  end
  def end_of_beat!
    {
      "move_and_move_trap" => ->(me, inpts){
        me.teleport_to_unoccupied_space!
        me.move_trap_anywhere!
      }
    }
  end
end

class Blight < Style
  def initialize
    super("blight", 0..2, 0, 0)
  end
  def start_of_beat!
    {
      "place_trap" => ->(me, inpt){ me.place_trap_in_range! }
    }
  end
end

class Evacuation < Style
  def initialize
    super("evacuation", 0..1, 0, 0)
  end
  def reveal!(me)
    me.dodge_trapped_opponents!
  end
  def start_of_beat!
    {
      "evacuation_place_trap_and_retrat" => ->(me,inpts){
        me.set_trap!(me.position)
        select_from_methods(retreat: [1]).call(me,inpts)
      }
    }
  end
end

class Lure < Style
  def initialize
    super("lure", 0..5, -1, -1)
  end
  def on_hit!
    {
      "lure_pull" => select_from_methods(pull: [0,1,2,3,4,5])
    }
  end
end

class Snare < Base
  def initialize
    super("snare", nil, 3, 1)
  end
  def passive!(me)
    me.no_moving_trap_this_beat!
    me.hits_on_and_adjacent_to_trap!
  end
  def stun_immunity?
    true
  end
end

class TrapPenalty < Token
  def initialize(amt)
    super("trap_penalty", 0, 0, amt)
  end
end

class Khadath < Character
  def self.character_name
    "khadath"
  end
  def initialize *args
    super
    @hand << Snare.new
    @hand += [
      Hunters.new,
      Teleport.new,
      Blight.new,
      Evacuation.new,
      Lure.new
    ]

    @trap = nil
  end

  def they_are_on_or_next_to_trap?
    @trap && (@opponent.position - @trap).abs <= 1
  end


  def hunters_bonus_if_on_or_adacent_to_trap!
    if they_are_on_or_next_to_trap?
      @hunters_bonus = true
    end
  end

  def power
    super + (@hunters_bonus ? 2 : 0)
  end
  def priority
    super + (@hunters_bonus ? 2 : 0)
  end

  def trap_blocks_ranged_attacks!
    @block_ranged_attacks = true
  end

  def move_trap_anywhere!
    select_from_methods(set_trap: [0,1,2,3,4,5,6]).call(self, @input_manager)
  end
  def set_trap?(n)
    return false if @no_moving_trap_this_beat
    @position != Integer(n) && @opponent.position != Integer(n)
  end
  def set_trap!(n)
    @trap = Integer(n)
  end

  def place_trap_in_range!
    select_from_methods(set_trap_in_range: [0,1,2,3,4,5,6]).call(self, @input_manager)
  end
  def set_trap_in_range?(n)
    return false if @no_moving_trap_this_beat
    if @position < @opponent.position
      dest = @position + Integer(n)
    else
      dest = @position - Integer(n)
    end
    # no one is on that location, and its within range)
    @position != dest && @opponent.position != dest &&
    range && range.include?(Integer(n)) && dest >=0 && dest <7
  end
  def set_trap_in_range!(n)
    if @position < @opponent.position
      @trap = @position + Integer(n)
    else
      @trap = @position - Integer(n)
    end
  end

  def dodge_trapped_opponents!
    @dodge_trapped_opponents = true
  end

  def dodge_ranged_attacks?
    return false unless @trap
    (@position < @trap && @trap < @opponent.position) ||
    (@position > @trap && @trap > @opponent.position) &&
    @block_ranged_attacks
  end

  def dodges?
    super || (@dodge_trapped_opponents && @opponent.position == @trap) || dodge_ranged_attacks?
  end

  def hits_on_and_adjacent_to_trap!
    @hits_on_and_adjacent_to_trap = true
  end

  def no_moving_trap_this_beat!
    @no_moving_trap_this_beat = true
  end

  def in_range?
    if @hits_on_and_adjacent_to_trap
      they_are_on_or_next_to_trap?
    else
      super
    end
  end

  def recycle
    super
    @hunters_bonus = false
    @block_ranged_attacks = false
    @dodge_trapped_opponents = false
    @no_moving_trap_this_beat = false
    @hits_on_and_adjacent_to_trap = false
  end

  def blocked_spaces
    if @trap
      if @trap < @opponent.position
        [@trap-1] + super
      elsif @trap > @opponent.position
        [@trap+1] + super
      else
        super
      end
    else
      super
    end
  end

  # effect sources provided by your opponent, like trap penalty
  def opponent_effect_sources
    rtn = []
    if they_are_on_or_next_to_trap?
      if @trap == @opponent.position
        rtn << TrapPenalty.new(-3)
      else
        rtn << TrapPenalty.new(-1)
      end
    end
    rtn + super
  end
  # these are current effects provided by your opponent, like trap penalty
  def current_opponent_effects
    rtn = []
    if they_are_on_or_next_to_trap?
      if @trap == @opponent.position
        rtn << "Gate Trap (-3 priority)"
      else
        rtn << "Gate Trap (-1 priority)"
      end
    end
    rtn + super
  end

  def extra_data
    {
      :trap => @trap
    }
  end
end
