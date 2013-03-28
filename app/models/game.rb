require 'game_play'
class Game < ActiveRecord::Base
  attr_accessible :inputs, :p0_id, :p1_id, :active
  serialize :inputs
  serialize :configs, Hash

  validate :p0_id, :p1_id, presence: true
  belongs_to :p0, :class_name => "User"
  belongs_to :p1, :class_name => "User"

  before_save :set_active_or_invalid
  before_create :decide_starting_player

  scope :active, where(:active => true)
  scope :inactive, where(:active => false)
  default_scope where(:valid_play => true)
  scope :for_user, ->(user) { Game.where('p0_id = ? OR p1_id = ?', user.id, user.id) }

  def play(idx=nil)
    GamePlay.new(configs[:starting_player], [p0.name, p1.name], inputs, idx)
  end
  def input_and_save!(player_id, action)
    g = GamePlay.new(configs[:starting_player], [p0.name, p1.name], inputs)
    # CANCEL BUTTON
    if action == "undo"
      if g.can_undo?(player_id) && g.active?
        loop do
          pn, _ = self.inputs.pop
          break if pn == player_id
        end

      else
        raise "Player #{player_id} tried to cancel when it was invalid."
      end
    else

      g.input!(player_id, action)
      self.inputs = g.valid_inputs
    end
    save!
  end

  def self.active_between(user, opponent)
    where(p0_id: user, p1_id: opponent, active: true).first ||
    where(p1_id: user, p0_id: opponent, active: true).first
  end

  def player_id(user)
    return 0 if p0 == user
    return 1 if p1 == user
  end

  def check_validity
    play && true
  rescue
    self.valid_play = false
    save!
  end

  private

  def set_active_or_invalid
    # If the game is invalid, it's no longer active.
    self.active = play.active?
    true
  rescue
    self.valid_play = false
    true
  end

  def decide_starting_player
    # totally random!
    self.configs[:starting_player] = rand(2)
  end
end
