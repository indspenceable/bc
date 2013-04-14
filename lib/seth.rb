require "character"
require "bases"

class Fools < Style
  def initialize
    super('fools', 0, -1, -4)
  end
  def start_of_beat!
    {
      "range_penalty" => ->(me, inputs) { me.fools_range_penalty!}
    }
  end
end
class Vanishing < Style
  def initialize
    super('vanishing', 1, 0, 0)
  end

  flag :dodge_range_four_and_up

  def start_of_beat!
    {
      "retreat" => select_from_methods(retreat: [0,1])
    }
  end
end
class Compelling < Style
  def initialize
    super('compelling', 0, 0, 0)
  end

  def before_activating!
    {
      "move_foe" => select_from_methods(pull: [0,1], push: [1])
    }
  end
  alias :after_activating! :before_activating!
end
class Mimics < Style
  def initialize
    super('mimics', 0, 1, 0)
  end

  # TODO implement this
  flag :mimic_movement
end
class Wyrding < Style
  def initialize
    super('wyrding', 0, 0, 1)
  end
  def start_of_beat!
    {
      "new_base" => ->(me, inputs) { me.select_new_base_if_correct_guess! }
    }
  end
end

class Omen < Base
  def initialize
    super('omen', 1, 3, 1)
  end
  def start_of_beat!
    {
      "stun" => ->(me, inputs) { me.stun_if_correct_guess! }
    }
  end
end

class SethFinisher1 < Finisher
  def initialize
    super("sethfinisher1", 1..3, 0, 6)
  end
  def on_hit!
    {
      "foresight" => ->(me, inputs) { me.foresight! }
    }
  end
end

class Foresight < Token
  def initialize
    super('foresight', 0, 0, 0)
  end
  flag :foresight
end

class FoolsRangePenalty < Token
  def initialize
    super('foolspenalty', -1, 0, 0)
  end
  def effect
    "-1 Range"
  end
end

class BeyondEyes < Token
  def initialize
    super("beyondeyesactivation", 0,0,0)
  end
  def reveal!(me)
    me.beyond_eyes!
  end
  def descriptor?
    false
  end
end

class BeyondEyesBonus < Token
  def initialize
    super('beyondeyes', 0, 2, 2)
  end
  def effect
    "+2 Power, +2 Priority"
  end
end

class Seth < Character
  def self.character_name
    "seth"
  end
  def initialize *args
    super
    @hand << Omen.new
    @hand += [
      Fools.new,
      Vanishing.new,
      Compelling.new,
      Mimics.new,
      Wyrding.new,
    ]
    @bonuses = []
    @opponent_bonuses = []
    @foresight_bonus = nil
  end

  def finishers
    [Omen.new]
  end

  def character_specific_effect_sources
    []
  end


  def ante_options
    opts = []
    unless @guess
      opts += @opponent.bases(player_id).map(&:name)
    end
    opts += super
    opts
  end

  def ante? option
    return true if super
    @opponent.bases(player_id).map(&:name).include?(option)
  end

  def ante! option
    @guess = option
  end

  def beyond_eyes!
    @correct_guess = (@opponent.base.name == @guess)
  end

  def correct_guess?
    @correct_guess
  end

  def character_specific_effect_sources
    Array(correct_guess?? BeyondEyes.new : nil) +
    Array(@foresight_bonuse)
  end

  def dodges?
    super || (flag?(:dodge_range_four_and_up) && distance >= 4)
  end

  def recycle!
    super
    @discard1 << @old_base if @old_base
    @old_base = nil
    @bonuses = []
    @opponent_bonuses = []
    @correct_guess = nil
    @guess = nil
  end

  # effect sources provided by your opponent, like trap penalty
  def opponent_effect_sources
    @opponent_bonuses
  end

  def fools_range_penalty!
    @opponent_bonuses << FoolsRangePenalty.new
  end

  def select_new_base? choice
    bases.map(&:name).include?(choice) || choice == "pass"
  end
  def select_new_base! choice
    return if choice == 'pass'
    base = bases.find{|x| x.name == choice}
    @old_base, @base = @base, base
    @hand.delete(base)
  end

  def select_new_base_if_correct_guess!
    if correct_guess?
      puts "bases is #{bases.inspect}"
      select_from_methods(select_new_base: bases.map(&:name) + ['pass']).call(me, @input_manager)
    end
  end

  def stun_if_correct_guess!
    opponent.stunned! if correct_guess?
  end

  def foresight!
    @foresight_bonus = Foresight.new
  end

end
