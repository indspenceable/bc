require 'game_play'
class Game < ActiveRecord::Base
  attr_accessible :inputs, :p0_id, :p1_id, :active
  serialize :inputs

  validate :p0_id, :p1_id, presence: true
  belongs_to :p0, :class_name => "User"
  belongs_to :p1, :class_name => "User"

  before_save :set_active

  scope :active, where(:active => true)

  def play
    GamePlay.new(inputs)
  end
  def input_and_save!(id, action)
    g = GamePlay.new(inputs)
    g.input!(id, action)
    self.inputs = g.valid_inputs
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
  end
end
