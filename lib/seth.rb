require "character"
require "bases"

class Fools < Style
  def initialize
    super('fools', 0, -1, -4)
  end
end
class Vanishing < Style
  def initialize
    super('vanishing', 1, 0, 0)
  end
end
class Compelling < Style
  def initialize
    super('compelling', 0, 0, 0)
  end
end
class Mimics < Style
  def initialize
    super('mimics', 0, 1, 0)
  end
end
class Wyrding < Style
  def initialize
    super('wyrding', 0, 0, 1)
  end
end

class Omen < Base
  def initialize
    super('omen', 1, 3, 1)
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
  end

  def finishers
    []
  end

  def character_specific_effect_sources
    []
  end


  def dodges?
    super || (flag?(:dodge_range_four_and_up) && range >= 4)
  end

  def recycle!
    super
    @bonuses = []
    @opponent_bonuses = []
  end

  # effect sources provided by your opponent, like trap penalty
  def opponent_effect_sources
    @opponent_bonuses
  end
end
