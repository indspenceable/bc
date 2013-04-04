require "character"
require "bases"

class BloodLetting < Style
  def initialize
    super("bloodletting", 0, -2, 3)
  end
  def ignore_soak?
    true
  end
end

class DarkSide < Style
  def initialize
    super("darkside", 0, -2, 1)
  end
  def on_hit!
    {
      'retreat' => select_from_methods("You may retreat to any space", retreat: [0,1,2,3,4,5,6])
    }
  end
end

class Illusory < Style
  def initialize
    super("illusory", 0, -1, 1)
  end
  def method_name
    
  end
end

class Jousting < Style
  def initialize
    super("jousting", 0, -2, 1)
  end
  def start_of_beat!
    {
    "advance" => ->(me, inputs) { me.advance_until_adjacent! }
    }
  end
  def on_hit!
    {
    'advance_to_end' => ->(me, inputs) { (6..0).each {|i| return me.advance!(i) if me.advance?(i)} }
    }
  end
end

class Vapid	 < Style
  def initialize
    super("vapid", (0..1), -1, 0)
  end
end

class DeathBlow	 < Base
  def initialize
  	super("deathblow", 1, 0, 8)
  end
end

class Crescendo < Token
  def initialize
  	super("crescendo", 0, 2, 0)
  end
  def effect
  	"+1 priority per token in pool. Ante for +2 power for each token anted"
  end
end

class CrescendoPoolEffect < Token
  def initalize
    super("crescendopooleffect", 0, 0, 1)
  end
end

class PrioBonusFromTokenPool < Token
  def initialize amt
    super("tokenpoolbonus", 0, 0, amt)
  end
  def effect
    "Passive +#{@priority} priority bonus from token pool."
  end
end

class SymphonyOfDemise < Finisher
  def initialize
    super("symphonyofdemise", 1, 0, 9)
  end
end

class Accelerando < Finisher
  def initialize 
    super("accelerando", 2, 2, 4)
  end 
end

class Demitras < Character
  def initialize *args
    super
    @hand << DeathBlow.new
    @hand += [
	  BloodLetting.new,
	  DarkSide.new,
	  Illusory.new,
	  Jousting.new,
	  Vapid.new
	  ]
    # of Available Tokens
    @number_of_tokens_in_pool = 2

  end


  def self.character_name
  	'demitras'
  end

  def recycle!
    super
    @number_of_tokens_in_pool = 2  
  end

  def ante?(choice)
    return true if choice == "pass"
    return true if super
  end

  def finishers
    [SymphonyOfDemise.new, Accelerando.new]
  end

  def advance_until_adjacent!
    if distance > 1
      advance!(distance-1)
    end
  end

  def character_specific_effect_sources
    sources = []
    sources << PrioBonusFromTokenPool.new(@number_of_tokens_in_pool)
    sources
  end


end