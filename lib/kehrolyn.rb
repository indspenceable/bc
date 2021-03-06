require "character"
require "bases"

class Bladed < Style
  def initialize
    super("bladed", 0, 2, 0)
  end
  def stun_guard
    2
  end
  def effect
    "+2 Power, Stun Guard 2"
  end
end

class Exoskeletal < Style
  def initialize
    super("exoskeletal", 0 , 0, 0)
  end

  flag :ignore_movement

  def soak
    2
  end
  def effect
    "Soak 2, Ignore Movement effects applied by opponents."
  end
end

class Mutating < Style
  def initialize
    super("mutating", 0, 0, 0)
  end

  # For what its worth- target will only be null if they played their finisher.

  def range
    @target ? @target.range : super
  end
  def power
    @target ? @target.power : super
  end
  def priority
    @target ? @target.priority : super
  end
  def soak
    @target ? @target.soak : 0
  end
  def stun_guard
    @target ? @target.stun_guard : 0
  end

  def reveal!(me)
    @target = me.mutating_target(self)
  end
  %w(start_of_beat! before_activating! on_hit! on_damage! after_activating!).each do |trigger|
    define_method(trigger) do
      @target && @target.respond_to?(trigger) ? @target.send(trigger) : {}
    end
  end
  def end_of_beat!
    (@target && @target.respond_to?(:end_of_beat!) ? @target.send(:end_of_beat!) : {})
      .merge('lose_life' => ->(me,_) { me.lose_life!(1)})
  end
  def effect
    "If Current form, duplicates current style. Otherwise, copies current form. End of Beat: Lose 1 life."
  end
end

class Quicksilver < Style
  def initialize
    super("quicksilver", 0, 0, 2)
  end
  def end_of_beat!
    {
      'advance' => select_from_methods("Move up to 1 space.", advance: [0, 1], retreat: [1])
    }
  end
  def effect
    "+2 Priority. End of Beat: Move up to 1 space."
  end
end

class Whip < Style
  def initialize
    super("whip", 0..1, 0 , 0)
  end
  def on_hit!
    {
      'hit_or_pull' => ->(me, inputs) { me.hit_or_pull! }
    }
  end
  def effect
    "0~1 Range. On Hit: if range > 1, pull 1. Otherwise, opponent is stunned."
  end
end

class Overload < Base
  def initialize
    super("overload", 1 , 3 , 3)
  end
  flag :loses_ties

  def start_of_beat!
    {
      "extra_style" => select_from_methods("(Overload) Select an additional style to apply to this attack.", select_extra_style: %w(bladed exoskeletal mutating quicksilver whip))
    }
  end
end

class HydraFork < Finisher
  def initialize
    super("hydrafork", 1..3, 6, 0)
  end
  def stun_immunity?
    true
  end
  def after_activating!
    {
      "regain_life" => ->(me, inputs) { me.gain_life!(5) }
    }
  end
end

class TheAugustStrain < Finisher
  def initialize
    super("theauguststrain", 1..2, 4, 5)
  end

  def stun_guard
    2
  end
  def soak
    2
  end
  def on_hit!
    {
      "perma_style" => select_from_methods("Select an additional style to add to all attacks for the rest of the game.", select_perma_style: %w(bladed exoskeletal mutating quicksilver whip))
    }
  end
end

class Kehrolyn < Character
  def initialize *args
    super

    @hand << Overload.new
    @hand += [
      Bladed.new,
      Exoskeletal.new,
      Mutating.new,
      Quicksilver.new,
      Whip.new
    ]

    @bonuses = []
  end

  def finishers
    [HydraFork.new, TheAugustStrain.new]
  end

  def character_specific_effect_sources
    sources = []
    sources << @perma_style if @perma_style
    sources << current_form
    sources += @bonuses
    sources
  end

  def self.character_name
    'kehrolyn'
  end

  def mutating_target(mutating)
    # if getting called by the current form, return the style OTHERWISE current_form
    if mutating == current_form
      @style
    else
      current_form
    end
  end

  def select_extra_style?(name)
    @hand.any?{|c| c.is_a?(Style) && c.name == name}
  end
  def select_extra_style!(name)
    new_style = @hand.find{|c| c.is_a?(Style) && c.name == name}
    @bonuses << new_style
    new_style.reveal!(self) if new_style.respond_to?(:reveal!)
  end

  def current_form
    @discard1 && @discard1.find{|c| c.is_a? Style }
  end

  def hit_or_pull!
    if distance > 1
      select_from_methods(pull: [1]).call(self, @input_manager)
    else
      opponent.stunned!
    end
  end

  def recycle!
    @bonuses = []
    super
  end

  def select_perma_style?(name)
    select_extra_style?(name)
  end
  def select_perma_style!(name)
    new_style = @hand.find{|c| c.is_a?(Style) && c.name == name}
    # if its mutating, make it apply to the current form.
    new_style.reveal!(self) if name == "mutating"
    @hand.delete(new_style)
    @perma_style = new_style
  end

end
