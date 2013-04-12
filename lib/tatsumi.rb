require "character"
require "base"

class Siren < Style
  def initialize
    super("siren", 0, -1, 1)
  end
  def on_hit!
    {
      #Opponent is stunned
      "stuns" => ->(me, inputs) {me.opponent.stunned!}
    }
  end
  def end_of_beat!
    {
      #Move Juto 0-2 spaces
      "move_juto" => ->(me, inputs) {
        select_from_methods(move_juto: ((me.juto.position-2)..(me.juto.position+2)).to_a).call(me, inputs)
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
      #juto between (zone 2), attacks at range 3+ do not hit tatsumi
      "range_block" => (me, inputs) {
        if me.character_specific_effect_sources[0] == me.zones[2]
          me.riptide_range_mod = true
        end
      }
    }
  end
  def end_of_beat!
    {
      #Move juto any amount toward you - including past you!
      "pull_juto" => (me, inputs) {
        if me.position < me.juto.position
          select_from_methods(move_juto: (0..(me.juto.position)).to_a).call(me, inputs)
        elsif me.position > me.juto.position
          select_from_methods(move_juto: ((me.juto.position)..6).to_a).call(me, inputs)
        end
      }
    }
  end
end

class Empathic < Style
  def initialize
    super("empathic", 0, -2, 1)
  end
  def after_activating!
    {
      #You may swap with Juto
      select_from_methods("Swap locations with Juto?", swap_juto: ["yes", "no"])
    }
  end
  def end_of_beat!
    {
      #Opponent loses life equal to half the damage you received - rounding up
      "opponent_lose_life" => ->(me, inputs) {
        damage = me.damage_taken_this_beat/2 + me.damage_taken_this_beat%2
        me.opponent.lose_life!(damage)
      }
    }
  end
end

class Fearless < Style
  # Range must be calculated from Juto; can't hit if he's disabled
  def initialize
    super("fearless", -1..0, -1, 1)
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
      "push" => select_from_methods(push: (0..2).to_a)
    }
  end
  def after_activating!
    {
      # advance juto any distance
      "advance_juto" => ->(me, inputs) {
        select_from_methods(move_juto: (0..(me.juto.position)).to_a).call(me, inputs) if me.opponent.position < me.juto.position
        select_from_methods(move_juto: ((me.juto.position)..6).to_a).call(me, inputs) if me.opponent.position > me.juto.position
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
          if me.character_specific_effect_sources[0] == me.zones[3]
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
      "move_tatsumi" => select_from_methods("Move Tatsumi 0-2 spaces", advance: [0, 1, 2], retreat: [1, 2])
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
  # attack does not hit if opponent is adjacent to juto
  def initialize
    super("tsunamiscollide", 2..4, 0, 0)
  end
  def reveal!(me)
    {
      # zone 3: +3 power, +2 priority per space between Tatsumi & Juto
      if me.character_specific_effect_sources[0] == me.zones[3]
        distance = (me.position-me.juto.position).abs - 1
        @power = 3 * distance
        @priority = 2 * distance
      end
    }
  end
  # This attack cannot hit opponents adjacent to Juto
  flag :tsunamis_collide_range_mod
end

class Juto
  attr_accessor :life, :position
  def initialize(position)
    @position = position
    @life = 4
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
    [TsunamisCollide.new, TsunamisCollide.new]
  end

  def character_specific_effect_sources
    return [] if @juto.life < 1
    # zone 1 if juto.position == tatsumi
    return [zones[1]] if @juto.position == @position
    if @position < @opponent.position
      # zone 0 if juto behind tatsumi
      return [zones[0]] if @juto.position < @position
      # zone 2 if juto between tatsumi and opponent
      return [zones[2]] if @juto.position < @opponent.position
    else
      # zone 0 if juto behind tatsumi
      return [zones[0]] if @juto.position > @position
      # zone 2 if juto between tatsumi and opponent
      return [zones[2]] if @juto.position > @opponent.position
    end
    # zone 3 if juto on same location or behind opponent
    return [zones[3]]
  end

  def in_range?
    return @juto.life > 0 && range && range.include?((@juto.position-@opponent.position).abs) && !@opponent.dodges? if base_flag?(:fearless)
    return false if base_flag?(:tsunamis_collide_range_mod) && ((@juto.position - 1)..(@juto.position + 1)).include?(@opponent.position)
    return true if super
  end

  def dodges?
    return true if super
    return (distance >= 3) if @riptide_range_mod
  end

  end
  def move_juto? n_s
    n = Integer(n_s)
    return true if (n>=0 && n<=6)
  end

  def move_juto! n_s
    @juto.position = Integer(n_s)
  end

  def swap_juto? response_s
    return true if @juto.life > 0
  end

  def swap_juto! response_s
    if response_s == "yes"
      temp = @position
      @position = @juto.position
      @juto.position = temp
    end
  end

  def revive_juto!
    if (@juto.life < 1)
      log_me!("revives Juto.")
      @juto.life = 4
      @juto.position = @position
    end
  end

  def take_hit!(damage)
    # If juto soaks, make him take damage
    unless opponent.ignore_soak?? && character_specific_effect_sources[0].soak
      @juto.life -= [character_specific_effect_sources[0].soak, damage].min
    end
  end

  def recycle!
    super
    @riptide_range_mod = false
    @juto.position = nil if @juto.life < 1
  end