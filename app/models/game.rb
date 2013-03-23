require 'game_play'
class Game < ActiveRecord::Base
  attr_accessible :inputs, :p0_id, :p1_id, :active
  serialize :inputs

  validate :p0_id, :p1_id, presence: true
  belongs_to :p0, :class_name => "User"
  belongs_to :p1, :class_name => "User"

  before_save :set_active
  before_create :decide_starting_player

  scope :active, where(:active => true)
  scope :inactive, where(:active => false)

  def play(idx=nil)
    GamePlay.new(starting_player, [p0.name, p1.name], inputs, idx)
  end
  def input_and_save!(player_id, action)
    g = GamePlay.new(starting_player, [p0.name, p1.name], inputs)
    # CANCEL BUTTON
    if action == "cancel"
      if g.can_cancel?(player_id)
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

  private

  def set_active
    self.active = play.active?
    true
  end

  def decide_starting_player
    # totally random!
    self.starting_player = rand(2)
  end
end
