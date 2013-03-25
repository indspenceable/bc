require "character"
require "bases"

class PointBlank < Style
  def initialize
    super("pointblank", (0..1), 0, 0)
  end
  def stun_guard
    2
  end
  def on_damage!
    {
      "push" => select_from_methods(push: [0,1,2])
    }
  end
end

class Gunner < Style
  def initialize
    super("gunner", (2..4), 0, 0)
  end
  def before_activating!
    {
      "extra_range" => select_from_methods(extra_range: Rukyuk.token_names)
    }
  end
  def after_activating!
    {
      "movement" => select_from_methods(advance: [1,2], retreat: [1,2])
    }
  end
end

class Crossfire < Style
  def initialize
    super("crossfire", (2..3), 0, -2)
  end
  def soak
    2
  end
  def on_hit!
    {
      "extra_damage" => select_from_methods(extra_power: Rukyuk.token_names)
    }
  end
end

class Sniper < Style
  def initialize
    super("sniper", (3..6), 1, 2)
  end
  def after_activating!
    {
      "movement" => select_from_methods(advance: [1,2,3], retreat: [1,2,3])
    }
  end
end

class Trick < Style
  def initialize
    super("trick", (1..2), 0, -3)
  end
  def stun_immunity?
    true
  end
end

class Reload < Base
  def initialize
    super("reload", nil, nil, 4)
  end
  def after_activating!
    {
      "teleport" => ->(me, inputs) {
        me.teleport_to_unoccupied_space!
      }
    }
  end
  def end_of_beat!
    {
      "get_tokens_back" => ->(me, inputs) {
        me.fill_token_pool!
      }
    }
  end
end

class ExplosiveShell < Token
  def initialize
    super("explosiveshell", 0, 2, 0)
  end
  def effect
    "+2 power"
  end
end
class SwiftShell < Token
  def initialize
    super("swiftshell", 0, 0, 2)
  end
  def effect
    "+2 priority"
  end
end
class Longshot < Token
  def initialize
    super("longshot", (-1..1), 0, 0)
  end
  def effect
    "-1~+1 range"
  end
end
class ImpactShell < Token
  def initialize
    super("impact", 0, 0, 0)
  end
  def on_hit!
    {
      "push" => select_from_methods(push: [2])
    }
  end
  def effect
    "On Hit: Push Opponent 2 spaces"
  end
end
class APShell < Token
  def initialize
    super("apshell", 0, 0, 0)
  end
  def ignore_soak?
    true
  end
  def effect
    "Ignore soak"
  end
end
class FlashShell < Token
  def initialize
    super("flashshell", 0, 0, 0)
  end
  def ignore_stun_guard?
    true
  end
  def effect
    "Ignore Stun Guard"
  end
end

class ForceGrenade < Finisher
  def initialize
    super("forcegrenade", 1..2, 4, 4)
  end

  flag :no_ammo_benefit
  flag :hit_without_ammo

  def on_hit!
    {
      "push" => select_from_methods(push: [0,1,2,3,4,5,6])
    }
  end
  def after_activating!
    {
      "retreat" => select_from_methods(retreat: [0,1,2,3,4,5,6])
    }
  end
end

class FullyAutomatic < Finisher
  def initialize
    super("fullyautomatic", 3..6, 2, 6)
  end
  flag :no_ammo_benefit

  def on_hit!
    {
      "repeat_attack" => select_from_methods(repeat_attack: Rukyuk.token_names)
    }
  end
end

class Rukyuk < Character
  def initialize *args
    super
    @hand << Reload.new
    @hand += [
      Gunner.new,
      Crossfire.new,
      PointBlank.new,
      Sniper.new,
      Trick.new,
    ]
    fill_token_pool!
    @bonuses = []
  end

  def finishers
    [FullyAutomatic.new, ForceGrenade.new]
  end

  def self.character_name
    'rukyuk'
  end

  def ante_options
    (@current_token ? [] : @token_pool.map(&:name)) + super
  end

  def ante!(choice)
    return if choice == "pass"
    return if super(choice)
    @current_token = @token_pool.find{ |token| token.name == choice }
    log_me!("antes #{@current_token.name} (#{@current_token.effect})")
    @token_pool.delete_if{ |token| token.name == choice }
  end

  def ante?(choice)
    return true if choice == "pass"
    return true if super(choice)
    @token_pool.any?{ |token| (token.name == choice) }
  end

  def extra_range?(choice)
    ante?(choice)
  end
  def extra_power?(choice)
    ante?(choice)
  end
  def repeat_attack?(choice)
    ante?(choice)
  end

  def extra_range!(choice)
    return if choice == "pass"
    @token_pool.delete_if{ |token| token.name == choice }
    @bonuses << Longshot.new
  end
  def extra_power!(choice)
    return if choice == "pass"
    @token_pool.delete_if{ |token| token.name == choice }
    @bonuses << ExplosiveShell.new
  end

  def repeat_attack!(choice)
    return if choice == "pass"
    @token_pool.delete_if{ |token| token.name == choice }
    execute_attack!
  end

  def character_specific_effect_sources
    sources = []
    # We can't call flag? here... boo.
    sources += Array(@current_token) unless sources.any?{|s| s.flag?(:no_ammo_benefit)}
    sources += @bonuses
    sources
  end

  def token_pool_descriptors
    @token_pool.map(&:descriptor)
  end

  def recycle!
    super
    @bonuses = []
    @current_token = nil
  end

  def in_range?
    super && @current_token
  end

  def self.token_names
    %w(explosiveshell swiftshell longshot
      apshell impactshell flashshell pass)
  end

  def fill_token_pool!
    @token_pool = self.class.all_token_klasses.map(&:new)
  end

  private

  def self.all_token_klasses
    [
      ExplosiveShell,
      SwiftShell,
      Longshot,
      APShell,
      FlashShell,
      ImpactShell,
    ]
  end

end
