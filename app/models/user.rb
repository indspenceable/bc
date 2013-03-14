class User < ActiveRecord::Base
  attr_accessible :email, :email_notifications_enabled, :chime_enabled
  serialize :metadata
  before_create :ensure_metadata_hash

  scope :except, ->(user) { where('NOT id = ?', user.id) }
  def games
    Game.where("p0_id = ? OR p1_id = ?", self.id, self.id)
  end

  def self.default_metadata
    {
      :email_notifications_enabled => "1",
      :chime_enabled => "1"
    }
  end

  def email_notifications_enabled
    metadata[:email_notifications_enabled]
  end
  def email_notifications_enabled=(v)
    metadata[:email_notifications_enabled]=v
  end
  def email_notifications_enabled?
    metadata[:email_notifications_enabled]=="1"
  end

  def chime_enabled
    metadata[:chime]
  end
  def chime_enabled=(v)
    metadata[:chime]=v
  end
  def chime_enabled?
    metadata[:chime]=="1"
  end

  private

  def ensure_metadata_hash
    self.metadata ||= self.class.default_metadata
  end
end
