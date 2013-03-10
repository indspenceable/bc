require "character"
require "bases"

class Anathema < Style
	def initialize
		super("anathema", 0, -1, -1)
	end
	def reveal!(me)
		# +1 power, +1 pri per token anted (up to 3)
	end
end

class Darkheart < Style
	def initialize
		super("darkheart", 0, 0, -1)
	end
	def on_hit!
		{
			gain_life!(2)
			#the opponent must discard a token if he has any
		}
	end
end

class Pactbond < Style
	def initialize
		super("pactbond", 0, -1, -1)
	end
	def reveal!(me)
		{
			#gain 1 life per token anted (2 max)
		}
	end
	def end_of_beat!
		{
			#choose a token to ante for free next round
		}
	end
end

class Necrotizing < Style
	def initialize
		super("necrotizing", 0..2, -1, 0)
	end
	def on_hit!
		{
			#spend life points to gain power (max 3)
		}
	end
end

class Accursed < Style
	def intialize
		super("accursed", 0..1, -1, 0)
	end
	def reveal!(me)
		{
			#gain stun immunity if anted 3 or more tokens
		}
	end
end

class Bloodlight < Base
	def initialize
		super("bloodlight", 1..3, 2, 3)
	end
	def on_damage!
		{
			# gain life per damage dealt, up to the number of tokens anted this turn
		}
	end
end

class Almighty < Token
	def initialize
		super("almighty", 0, 2, 0)
	end
	def name_and_effect
		"#{name.capitalize} (+2 power)"
	end
end

class Endless < Token
	def initialize
		super("almighty", 0, 0, 2)
	end
	def name_and_effect
		"#{name.capitalize} (+2 priority)"
	end
end

class Immortality < Token
	def initialize
		super("immortality", 0, 0, 0)
	end
	def name_and_effect
		"#{name.capitalize} (soak 2)"
	end
	def soak
		2
	end
end

class Inevitable < Token
	def initialize
		super("inevitable", 0..1, 0, 0)
	end
	def name_and_effect
		"#{name.capitalize} (0 ~ +1 range)"
	end
end

class Corruption < Token
	def initialize
		super("corruption", 0, 0, 0)
	end
	def name_and_effect
		"#{name.capitalize} (ignores stun guard)"
	end
	def ignore_stun_guard?
		true
	end
end

class Altazziar < Finisher
	def initialize
		super("altazziar", 1, 6, 2)
	end
	def start_of_beat
		lose_life!(@life - 1)
	end


class Hepzibah < Character
	def self.character_name
		"hepzibah"
	end
	def initialize *args
		super

		# set up hand
		@hand << Bloodlight.new
		@hand += [
			Anathema.new,
			Darkheart.new,
			Pactbond.new,
			Necrotizing.new,
			Accursed.new
		]
		# available tokens
		@token_pool = [
			Almighty.new,
			Endless.new,
			Immortality.new,
			Inevitable.new,
			Corruption.new
		]
		# tokens used this beat
		@current_tokens = []
	end

	def effect_sources
		super + @current_tokens
	end

	def ante_options
		((@life > 1) ? @token_pool.map(&:name) : []) + super
	end

	def ante!(choice)
		if choice == "pass"
			log_me!("passes.")
			return
		end
		log_me!("antes #{@token_pool.find{ |token| token.name == choice }.name_and_effect}")
		@current_tokens += @token_pool.reject{ |token| token.name != choice }
		lose_life!(1)
		@token_pool.delete_if{ |token| token.name == choice }
	end
