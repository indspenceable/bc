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
      "point_blank_push" => select_from_methods(push: [0,1,2])
    }
  end
end

class Gunner < Style
  def initialize
    super("gunner", (2..4), 0, 0)
  end
  def before_activating!
    {
      "gunner_extra_range" => select_from_methods(extra_range: Rukyuk.token_names)
    }
  end
  def after_activating!
    {
      "gunner_movement" => select_from_methods(advance: [1,2], retreat: [1,2])
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
      "crossfire_on_hit" => select_from_methods(extra_power: Rukyuk.token_names)
    }
  end
end

class Sniper < Style
  def initialize
    super("sniper", (3..6), 1, 2)
  end
  def after_activating!
    {
      "sniper_movement" => select_from_methods(advance: [1,2,3], retreat: [1,2,3])
    }
  end
end

class Trick < Style
  def initialize
    super("trick", (1..2), 0, -3)
  end
  def stun_immunity
    true
  end
end

class Reload < Base
  def initialize
    super("reload", nil, nil, 4)
  end
  def after_activating!
    {
      "reload_movement" => ->(me, inputs) {
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
  def name_and_effect
    "#{name.capitalize} (+2 power)"
  end
end
class SwiftShell < Token
  def initialize
    super("swiftshell", 0, 0, 2)
  end
  def name_and_effect
    "#{name.capitalize} (+2 priority)"
  end
end
class Longshot < Token
  def initialize
    super("longshot", (-1..1), 0, 0)
  end
  def name_and_effect
    "#{name.capitalize} (-1~+1 range)"
  end
end
class ImpactShell < Token
  def initialize
    super("impact", 0, 0, 0)
  end
  def on_hit!
    {
      "push_shell_push" => select_from_methods(push: [2])
    }
  end
  def name_and_effect
    "#{name.capitalize} (On Hit: Push Opponent 2 spaces)"
  end
end
class APShell < Token
  def initialize
    super("apshell", 0, 0, 0)
  end
  def ignore_soak?
    true
  end
  def name_and_effect
    "#{name.capitalize} (Ignore soak)"
  end
end
class FlashShell < Token
  def initialize
    super("flashshell", 0, 0, 0)
  end
  def ignore_stun_guard?
    true
  end
  def name_and_effect
    "#{name.capitalize} (Ignore Stun Guard)"
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

  def self.character_name
    'rukyuk'
  end

  def can_ante?
    @token_pool.any?
  end

  def ante_options
    (@current_token ? [] : @token_pool.map(&:name)) + super
  end

  def ante!(choice)
    return if choice == "pass"
    log_me!("antes #{@token_pool.find{ |token| token.name == choice }.name_and_effect}")
    @current_token = @token_pool.find{ |token| token.name == choice }
    @token_pool.delete_if{ |token| token.name == choice }
  end

  def ante?(choice)
    return true if choice == "pass"
    @token_pool.any?{ |token| (token.name == choice) }
  end

  def extra_range?(choice)
    ante?(choice)
  end
  def extra_power?(choice)
    ante?(choice)
  end

  def extra_range!(choice)
    @token_pool.delete_if{ |token| token.name == choice }
    @bonuses << Longshot.new
  end
  def extra_power!(choice)
    @token_pool.delete_if{ |token| token.name == choice }
    @bonuses << ExplosiveShell.new
  end

  def effect_sources
    Array(@current_token) + super
  end

  def current_effects
    Array(@current_token.try(:name_and_effect)) + super
  end

  def token_pool
    @token_pool.map(&:name_and_effect)
  end

  def recycle!
    super
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

  def recycle
    @bonuses = []
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
