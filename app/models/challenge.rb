class Challenge < ActiveRecord::Base
  # All of the configs!
  def self.configs
    # [:allow_mirror_matches, :use_finishers, :use_special_actions, :real_time]
    []
  end

  attr_accessible :configs, :from_id, :to_id
  attr_accessible *self.configs
  serialize :configs, Hash
  after_initialize :set_default_configs
  default_scope where(:inactive => false)

  belongs_to :receiving_user, class_name: "User", foreign_key: "to_id"
  belongs_to :issuing_user, class_name: "User", foreign_key: "from_id"
  validates :receiving_user, presence: true
  validates :issuing_user, presence: true
  validate :no_challenge_between_same_two_users

  scope :outgoing_by, ->(user) { where(:from_id => user.id) }
  scope :incoming_for, ->(user) { where(:to_id => user.id) }

  def no_challenge_between_same_two_users
    return if inactive
    if Game.active_between(receiving_user.id, issuing_user.id)
      errors.add(:receiving_user, "is in the middle of a game with you!")
    end
    if to_id
      if Challenge.where(:to_id => receiving_user, from_id: issuing_user).exists?
        errors.add(:receiving_user, "already has a challenge from you.")
      end
      if Challenge.where(:from_id => receiving_user, to_id: issuing_user).exists?
        errors.add(:receiving_user, "has already issued a challenge to you.")
      end
    end
  end

  def opponent
    receiving_user.name rescue ""
  end
  def issuer_name
    issuing_user.name
  end

  def set_default_configs
    self.configs = self.class.default_configs.merge(self.configs)
  end

  def self.default_configs
    {
      allow_mirror_matches: true,
      real_time: false,
      use_finishers: true,
      use_special_actions: true
    }
  end
  configs.each do |config|
    define_method(config) do
      puts "COnfigs is #{configs}"
      self.configs[config]
    end
    define_method("#{config}=") do |v|
      self.configs[config] = v
    end
  end

  def build_game_and_mark_inactive!
    return if inactive
    game = Game.new
    game.p0 = issuing_user
    game.p1 = receiving_user
    game.inputs = []
    game.configs = configs
    game.save!
    self.inactive = true
    save!
    game
  end

end
