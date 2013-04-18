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

  flag :darksidedodge

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

  def on_hit!
    {
      'stun_slow_opponent' => ->(me, inputs) { me.stun_slow_opponent}
    }
  end 
end

class DeathBlow	 < Base
  def initialize
  	super("deathblow", 1, 0, 8)
  end
end

class CrescendoPoolEffect < Token
  def initalize
    super("crescendopooleffect", 0, 0, 1)
  end
end

class PrioBonusFromTokenPool < Token
  def initialize amt
    super("Crescendo Priority Bonus", 0, 0, amt)
  end
  def effect
    "Passive +#{@priority} priority bonus from Crescendo Tokens in pool."
  end
end

class Crescendo < Token
  def initialize
    super("Crescendo", 0, 2, 0)
  end
  def effect
    "Ante for +2 power per token. Passively give +1 priority while in token pool"
  end
end

class OnHitLoseToken < Token
  def initialize
    super("lose_crescendo_on_hit", 0, 0, 0)
  end
  def oh_hit!
    {
      'lose_crescendo' => ->(me,inputs) {me.lose_crescendo}
    }
  end
  def effect 
    "On Hit; reduce the number of Crescendo Tokens Demitras currently owns by 1"
  end
end

class OnHitGainToken < Token
  def initialize
    super("Gain Crescendo On Hit", 0, 0, 0)
  end
  def oh_hit!
    {
      'gain_crescendo' => ->(me,inputs) {me.gain_crescendo}
    }
  end
  def effect 
    "On Hit; increase the number of Crescendo Tokens Demitras currently owns by 1"
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
    @token_pool = [Crescendo.new, Crescendo.new]
    @num_anted_tokens = 0
  end

  def self.character_name
  	'demitras'
  end

  def token_pool_descriptors
    @token_pool.map(&:descriptor)
  end 


  def dodges?
    return true if super
    return (distance > 3) if flag? :darksidedodge
  end

  def recycle!
    super
    @num_anted_tokens = 0
  end

  def ante_options?
    ((@number_of_tokens_in_pool < 1) ? [] : ["crescendo"]) + super
  end

  def ante?(action)
    return true if action == "pass"
    return true if super
    return next_available_crescendo && lose_crescendo
  end

  def finishers
    [SymphonyOfDemise.new, Accelerando.new]
  end

  def advance_until_adjacent!
    if distance > 1
      advance!(distance-1)
    end
  end


  def stun_slow_opponent
    opponent.stunned! if opponent.priority <= 3
  end

  def lose_crescendo
    if @number_of_tokens_in_pool > 0
      @number_of_tokens_in_pool -= 1
      log_me!(@number_of_tokens_in_pool)
      Crescendo.amount = @number_of_tokens_in_pool
    end
  end

  def gain_crescendo
    if @number_of_tokens_in_pool < 5
      @number_of_tokens_in_pool += 1
      log_me!(@number_of_tokens_in_pool)
      Crescendo.amount = @number_of_tokens_in_pool
    end
  end

  def next_available_crescendo
    @token_pool.find{|n| n.is_a? Crescendo}
  end

  def character_specific_effect_sources
    sources = []
    sources << PrioBonusFromTokenPool.new(@number_of_tokens_in_pool)
    sources << OnHitGainToken.new
    sources
  end

  def opponent_effect_sources
    return @number_of_tokens_in_pool > 0 ? [OnHitLoseToken.new] : []
  end  
end
