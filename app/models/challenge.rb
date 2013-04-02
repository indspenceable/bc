class Challenge < ActiveRecord::Base
  # All of the configs!
  def self.configs
    [:allow_mirror_matches, :use_finishers, :use_special_actions, :real_time]
  end

  attr_accessible :configs, :from_id, :to_id
  attr_accessible *self.configs
  serialize :configs, Hash
  after_initialize :set_default_configs

  def opponent
    User.find(to_id).name if to_id
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

end
