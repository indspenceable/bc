require "character"
require "bases"

class BloodLetting < Style
	def initialize
		super("bloodletting", 0, -2, 3)
	end
end

class DarkSide < Style
	def initialize
		super("darkside", 0, -2, 1)
	end
end

class Illusory < Style
	def initialize
		super("illusory", 0, -1, 1)
	end
end

class Jousting < Style
	def initialize
		super("jousting", 0, -2, 1)
	end
end

class Vapid	 < Style
	def initialize
		super("vapid", (0..1), -1, 0)
	end
end

class DeathBlow	 < Style
	def initialize
		super("deathblow", 1, 0, 8)
	end
end

class Crescendo < Token
	def initialize
		super("crescendo", 0, 2, 0)
	end
	def effect
		"+1 priority per token in pool. Ante for +2 power for each token anted"
	end
end

class SymphonyOfDemise < Finisher
	def initialize
		super("symphonyofdemise", 1, 0, 9)
	end
end

class Demitras < Character
	def initialize *args
		super
		@hand << DeathBlow.new
		@hand += [
			BloodLetting.new,
			DarkSide.new,
			Illusory.new,
			Jousting.new,
			Vapid.new
		]
	end
	def self.character_name
		'demitras'
	end
end