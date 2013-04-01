require "character"
require "bases"

class Hunters < Style
  def initialize
    super("hunters", 0, 1, 0)
  end
  def reveal!(me)
    me.hunters_bonus_if_on_or_adacent_to_trap!
  end
end

class Teleport < Style
  def initialize
    super("teleport", 0..2, 1, -4)
  end
  flag :trap_blocks_ranged_attacks
  def end_of_beat!
    {
      "move_and_move_trap" => ->(me, inpts){
        me.teleport_to_unoccupied_space!("(Teleport) Teleport anywhere.")
        me.move_trap_anywhere!("(Teleport) Move trap anywhere anywhere.")
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
      "place_trap_and_retrat" => ->(me,inpts){
        me.set_trap!(me.position) unless me.flag? :no_moving_trap_this_beat
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
      "pull" => select_from_methods("(Lure) Pull opponent any number of spaces.", pull: [0,1,2,3,4,5])
    }
  end
end

class Snare < Base
  def initialize
    super("snare", nil, 3, 1)
  end

  flag :no_moving_trap_this_beat
  flag :hits_on_and_adjacent_to_trap

  def stun_immunity?
    true
  end
end

class TrapPenalty < Token
  def initialize(amt)
    super("trap_penalty", 0, 0, amt)
  end
  def effect
    "#{@priority} priority"
  end
end

class HuntersBonus < Token
  def initialize
    super("hunters_bonus", 0, 2, 2)
  end
  def effect
    "+2 Power, +2 Priority"
  end
end

class DimensionalExile < Finisher
  def initialize
    super("dimensionalexile", nil, 25, 0)
  end
  def stun_immunity?
    true
  end

  flag :hits_on_trap
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

  def finishers
    [DimensionalExile.new, DimensionalExile.new]
  end

  def they_are_on_or_next_to_trap?
    @trap && (@opponent.position - @trap).abs <= 1
  end


  def hunters_bonus_if_on_or_adacent_to_trap!
    if they_are_on_or_next_to_trap?
      @hunters_bonus = HuntersBonus.new
    end
  end

  def character_specific_effect_sources
    Array(@hunters_bonus)
  end

  # def trap_blocks_ranged_attacks!
  #   @block_ranged_attacks = true
  # end

  def move_trap_anywhere!(str)
    select_from_methods(str, set_trap: [0,1,2,3,4,5,6]).call(self, @input_manager)
  end
  def set_trap?(n)
    return false if flag? :no_moving_trap_this_beat
    return n if @position != Integer(n) && @opponent.position != Integer(n)
  end
  def set_trap!(n)
    @trap = Integer(n)
  end

  def place_trap_in_range!
    select_from_methods("Place trap in range.", set_trap_in_range: [0,1,2,3,4,5,6]).call(self, @input_manager)
  end
  def set_trap_in_range?(n)
    return false if flag? :no_moving_trap_this_beat
    if @position < @opponent.position
      dest = @position + Integer(n)
    else
      dest = @position - Integer(n)
    end
    # no one is on that location, and its within range)
    @position != dest && @opponent.position != dest &&
    range && range.include?(Integer(n)) && dest >=0 && dest <7 &&
    # return the board position that this enables.
    dest
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
    return false unless flag? :trap_blocks_ranged_attacks
    (@position < @trap && @trap < @opponent.position) ||
    (@position > @trap && @trap > @opponent.position)
  end

  def dodges?
    super || (@dodge_trapped_opponents && @opponent.position == @trap) || dodge_ranged_attacks?
  end


  def in_range?
    if flag? :hits_on_and_adjacent_to_trap
      they_are_on_or_next_to_trap?
    elsif flag? :hits_on_trap
      @trap == opponent.position
    else
      super
    end
  end

  def recycle!
    super
    @hunters_bonus = nil
    @block_ranged_attacks = nil
    @dodge_trapped_opponents = nil
  end

  def blocked_spaces(direct_movement)
    if !direct_movement && @trap
      if @trap < @opponent.position
        return [@trap-1] + super
      elsif @trap > @opponent.position
        return [@trap+1] + super
      end
    end
    super
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

  def extra_data
    {
      :trap => @trap
    }
  end
end
