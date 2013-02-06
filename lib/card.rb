class Card
  attr_reader :name, :power, :priority, :range
  def initialize name, range, power, priority
    @name = name
    @power = power
    @priority = priority
    @range = range
  end

  # override methods if needed
  %w(reveal start_of_beat, before_activating on_hit on_damage after_activating
    end_of_beat).each do |meth|
    define_method(meth) do
      # blank methods, by default
    end
  end

  def stun_guard
    0
  end
  def soak
    0
  end
end

class Style < Card;end
class Base < Card;end
class Token < Card;end
