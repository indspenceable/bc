require "character"
require "bases"

class Siren < Style
  def initialize
    super("siren", 0, -1, 1)
  end
  def on_hit!
    {
      # Opponent is stunned
      "stuns" => ->(me, inputs) {me.opponent.stunned!}
    }
  end
  def end_of_beat!
    {
      # Move Juto 0-2 spaces
      "move_juto" => ->(me, inputs) {
          pos = Integer(me.juto.position)
          select_from_methods("Move Juto 0-2 spaces", move_juto: ((pos-2)..(pos+2)).to_a).call(me, inputs)
      }
    }
  end
end

class Riptide < Style
  def initialize
    super("riptide", 0..2, 0, -1)
  end
  def start_of_beat!
    {
      # Juto between (zone 2), attacks at range 3+ do not hit tatsumi
      "range_block" => ->(me, inputs) {
        if me.current_zone == me.zones[2]
          me.riptide_range_mod = true
        end
      }
    }
  end
  def end_of_beat!
    {
      # Move juto any amount toward you - including past you!
      "pull_juto" => ->(me, inputs) {
        if me.position < me.juto.position
          select_from_methods("Pull Juto any amount", move_juto: (0..(me.juto.position)).to_a).call(me, inputs)
        elsif me.position > me.juto.position
          select_from_methods("Pull Juto any amount", move_juto: ((me.juto.position)..6).to_a).call(me, inputs)
        end
      }
    }
  end
end

class Empathic < Style
  def initialize
    super("empathic", 0, 0, -2)
  end
  def after_activating!
    {
      # You may swap with Juto
      "swap_with_juto" => select_from_methods("Swap locations with Juto?", swap_juto: ["yes", "no"])
    }
  end
  def end_of_beat!
    {
      # Opponent loses life equal to the amount received by Juto
      "opponent_lose_life" => ->(me, inputs) {
        damage = me.juto.damage_taken_this_beat
        me.opponent.lose_life!(damage) if damage > 0
      }
    }
  end
  def stun_guard
    4
  end
end

class Fearless < Style
  # Range must be calculated from Juto; can't hit if he's disabled
  def initialize
    super("fearless", -1..0, 0, 1)
  end
  def end_of_beat
    #if Juto is disabled, revive him in your space
    {
      "revive_juto" => ->(me, inputs) {
        me.revive_juto!
      }
    }
  end
  flag :fearless
end

class Wave < Style
  def initialize
    super("wave", 2..4, -1, 0)
  end
  def on_hit!
    {
      #Push opponent 0-2 spaces
      "push" => select_from_methods("Push opponent 0-2 spaces", push: (0..2).to_a)
    }
  end
  def after_activating!
    {
      # advance juto any distance
      "advance_juto" => ->(me, inputs) {
        if me.opponent.position < me.juto.position
          select_from_methods("Advance Juto any distance", move_juto: (0..(me.juto.position)).to_a).call(me, inputs)
        elsif  me.opponent.position > me.juto.position
          select_from_methods("Advance Juto any distance", move_juto: ((me.juto.position)..6).to_a).call(me, inputs)
        end
      }
    }
  end
end

class Whirlpool < Base
  def initialize
    super("whirlpool", 1..2, 3, 3)
  end
  def start_of_beat!
    {
      # Move foe one space towards Juto 
      "move_opponent" => ->(me, inputs) {
        if me.opponent.position != me.juto.position
          if me.current_zone == me.zones[3]
            select_from_methods(retreat: [1]).call(me.opponent, inputs)
          else
            select_from_methods(advance: [1]).call(me.opponent, inputs)
          end
        end
      }
    }
  end
  def after_activating!
    {
      # You and Juto both move 0-2 spaces
      "move_juto" => ->(me, inputs) {
        select_from_methods("Move Juto 0-2 spaces", move_juto: ((me.juto.position-2)..(me.juto.position+2)).to_a).call(me, inputs)
      },
      "move_tatsumi" => select_from_movement_methods("Move Tatsumi 0-2 spaces", advance: [0, 1, 2], retreat: [1, 2])
    }
  end
end

class Zone0 < Token
  # Behind Tatsumi
  def initialize
    super("zone0", 0..2, 1, 0)
  end
  def effect
    "+0~2 range, +1 power"
  end
end

class Zone1 < Token
  # Same space as Tatsumi
  def initialize
    super("zone1", 0, 0, 0)
  end
  # Soak is not affected by Juto's life. http://forum.lvl99games.com/viewtopic.php?f=12&t=1686
  def soak
    3
  end
  def effect
    "soak 3"
  end
end

class Zone2 < Token
  # In betwwen Tatsumi and an opponent
  def initialize
    super("zone2", 0, 0, 0)
  end
  def soak
    1
  end
  def stun_guard
    2
  end
  def effect
    "soak 1, stun guard 2"
  end
end

class Zone3 < Token
  # On the same space as or behind an opponent
  def initialize
    super("zone3", 0, 0, 1)
  end
  def effect
    "+1 priority"
  end
end

class TsunamisCollide < Finisher
  def initialize
    super("tsunamiscollide", 2..4, 0, 0)
  end
  def reveal!(me)
      # zone 3: +3 power, +2 priority per space between Tatsumi & Juto
      me.tsunamis_collide!
  end
  # This attack cannot hit opponents adjacent to Juto
  flag :tsunamis_collide_range_mod
end

class TsunamisCollideBonus < Token
  def initialize distance
    super("Tsunamis Collide", 0, 3*distance, 2*distance)
  end
  def effect
    "+#{@power} power, +#{@priority} priority"
  end
end

class BearArms < Finisher
  # Range is Juto's space and adjacent spaces
  def initialize
    super("beararms", nil, 6, 5)
  end
  def on_hit!
    {
      # Opponent is stunned
      "stuns" => ->(me, inputs) {me.opponent.stunned!},
      # Move Juto any number of spaces
      "move_juto" => select_from_methods("Move Juto to any space", move_juto: (0..6).to_a)
    }
  end
  flag :bear_arms_range_mod
end

class Juto
  attr_accessor :life, :position, :damage_taken_this_beat
  def initialize(position)
    @position = position
    @life = 4
    @damage_taken_this_beat = 0
  end

  def take_hit!(damage)
    @life -= damage
    @damage_taken_this_beat += damage
    @position = -1 if @life < 1
  end

  def recycle!
    @damage_taken_this_beat = 0
  end

  def alive?
    return @life > 0
  end
end

class Tatsumi < Character
  attr_accessor :riptide_range_mod
  attr_reader :juto, :zones
  def self.character_name
    "tatsumi"
  end

  def initialize *args
    super

    @hand << Whirlpool.new
    @hand += [
      Siren.new,
      Riptide.new,
      Empathic.new,
      Fearless.new,
      Wave.new
    ]
    @juto = Juto.new(@position)
    @zones = [
      Zone0.new,
      Zone1.new,
      Zone2.new,
      Zone3.new
    ]
    @riptide_range_mod = false
  end

  def finishers
    [TsunamisCollide.new, BearArms.new]
  end

  def character_specific_effect_sources
    ret = []
    ret << current_zone if current_zone
    ret << @tsunamis_collide_bonus if @tsunamis_collide_bonus
    ret
  end

  def tsunamis_collide!
    distance = (@position-@juto.position).abs - 1
    @tsunamis_collide_bonus = TsunamisCollideBonus.new(distance)
  end

  def current_zone
    return nil unless @juto.alive?
    # zone 1 if juto.position == tatsumi
    return zones[1] if @juto.position == @position
    if @position < @opponent.position
      # zone 0 if juto behind tatsumi
      return zones[0] if @juto.position < @position
      # zone 2 if juto between tatsumi and opponent
      return zones[2] if @juto.position < @opponent.position
    else
      # zone 0 if juto behind tatsumi
      return zones[0] if @juto.position > @position
      # zone 2 if juto between tatsumi and opponent
      return zones[2] if @juto.position > @opponent.position
    end
    # zone 3 if juto on same location or behind opponent
    return zones[3]
  end

  def in_range?
    return @juto.alive? && range && range.include?((@juto.position-@opponent.position).abs) && !@opponent.dodges? if base_flag?(:fearless)
    return @juto.alive? && ((@juto.position - 1)..(@juto.position + 1)).include?(@opponent.position) if base_flag?(:bear_arms_range_mod)
    return false if base_flag?(:tsunamis_collide_range_mod) && ((@juto.position - 1)..(@juto.position + 1)).include?(@opponent.position)
    super
  end

  def dodges?
    return (distance >= 3) if @riptide_range_mod
    super
  end

  def move_juto? space
    return false unless @juto.alive?
    n = Integer(space)
    return n if (n>=0 && n<=6)
    return false
  end

  def move_juto! space
    @juto.position = Integer(space)
  end

  def swap_juto? response_s
    return (@juto.life > 0 && @juto.position!=@opponent.position)
  end

  def swap_juto! response_s
    if response_s == "yes"
      temp = @position
      @position = @juto.position
      @juto.position = temp
    end
  end

  def revive_juto!
    unless juto.alive?
      log_me!("revives Juto.")
      @juto.life = 4
      @juto.position = @position
    end
  end

  def take_hit!(damage)
    # If juto soaks, make him take damage
    unless (!juto.alive? || (opponent.ignore_soak? && !current_zone.soak))
      @juto.take_hit!([current_zone.soak, damage].min)
    end
    super
  end

  def recycle!
    super
    @riptide_range_mod = false
    @juto.recycle!
    @tsunamis_collide_bonus = nil
  end

  def extra_data
    {
      :juto => [@juto.position, @juto.life]
    }
  end
end