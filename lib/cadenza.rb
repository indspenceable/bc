require_relative "character"
require_relative "bases"

class Battery < Style
  def initialize
    super("battery", 0, 1, -1)
  end
  def end_of_beat!
    {
      "battery_charge" => ->(me, inpt) {
        me.charge_battery!
      }
    }
  end
end

class Clockwork < Style
  def initialize
    super("clockwork", 0, 3, -3)
  end
  def soak
    3
  end
end

class Hydraulic < Style
  def initialize
    super("hydraulic", 0, 2, -1)
  end
  def soak
    1
  end
  def before_activating!
    {
      "hydraulic_advance" => select_from_methods(advance: [1])
    }
  end
end

class Mechanical < Style
  def initialize
    super("mechanical", 0, 2, -2)
  end

  def end_of_beat!
    {
      "mechanical_advance" => select_from_methods(advance: [0,1,2,3])
    }
  end
end
class Grapnel < Style
  def initialize
    super("grapnel", 2..4, 0, 0)
  end

  def on_hit!
    {
      "grapnel_pull" => select_from_methods(pull: [0,1,2,3])
    }
  end
end

class Press < Base
  def initialize
    super("press", 1..2, 1, 0)
  end
  def stun_guard
    6
  end
  def reveal!(me)
    me.reveal_press!
  end
end

class IronBodyStunImmunity < Token
  def stun_immunity
    true
  end
end

class Cadenza < Character
  def initialize *args
    super

    @token_count = 0
  end
  def self.character_name
    'cadenza'
  end
  def charge_battery!
    @battery_charge = true
  end
  def reveal_press!
    @press_charge_up = true
  end

  def recieve_damage!(damage)
    if damage > 0 && @token_count > 0
      select_from_methods(iron_body: ['yes', 'pass']).call(me, @input_manager)
    end
  end

  def iron_body?(action)
    return true if action == "pass"
    return true if @token_count > 0
  end
  def iron_body!(action)
    return if action == "pass"
    @token_count -= 1
    @iron_body_stun_guard = true
  end

  def exceeds_stun_guard?(amt)
    return false if @iron_body_stun_guard
    super(amt)
  end

  def power
    super + (@press_charge_up ? @press_charge_ammount : 0)
  end
  def priority
    (@battery_bonus ? 4 : 0) + super
  end
  def token_pool
    (["Iron Body Token"] * @token_count) + super
  end

  #ante-ing iron body tokens
  def ante_options
    (@iron_body_stun_immunity ? [] : ["Iron Body"]) + super
  end

  alias ante? iron_body?
  def iron_body!(action)
    return if action == "pass"
    @token_count -= 1
    @iron_body_stun_immunity = true
  end

  def recycle!
    @battery_bonus = @battery_charge
    @battery_charge = nil

    @press_charge_up = nil
    @press_charge_ammount = 0

    @iron_body_stun_guard = false
    @iron_body_stun_immunity = false
    super
  end
end
