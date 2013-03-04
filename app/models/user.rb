class User < ActiveRecord::Base
  attr_accessible :email

  scope :except, ->(user) { where('NOT id = ?', user.id) }
  def games
    Game.where("p0_id = ? OR p1_id = ?", self.id, self.id)
  end


end
