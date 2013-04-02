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

  def no_challenge_between_same_two_users
    if Challenge.where(:to_id => receiving_user, from_id: issuing_user).exists? ||
      Challenge.where(:from_id => receiving_user, to_id: issuing_user)
      errors.add(:receiving_user, "already has an open challenge between with you.") if to_id
    end
  end

  def opponent
    receiving_user.name rescue ""
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
