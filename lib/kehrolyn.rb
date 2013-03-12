require "character"
require "bases"

class Bladed < Style
	def intialize
		super("bladed", 0, 2, 0)
	end
	def stun_guard
		2
	end
end

class Exoskeletal
	def intialize
		super("exoskeletal", 0 , 0, 0)
	end
	def soak
		2
	end
end

class Mutating
	def intialize
		super("mutating", 0, 0, 0)
	end
	def reveal!
	end
	def end_of_beat!
	end
end

class Quicksilver
	def intialize
		super("quicksilver", 0, 0, 2)
	end
	def end_of_beat!
		{
			'advance' => select_from_methods(advance: [0, 1])
		}
	end
end

class Whip
	def initalize
		super("whip", 0..1, 0 , 0)
	end
end

class Overload < Base
	def initalize
		super("overload", 1 , 3 , 2.9)
	end
	def start_of_beat!
	end
end


class Kehrolyn < Character
	def initialize *args
	@hand << Overload.new
	@hand += [
		Bladed.new,
		Exoskeletal.new,
		Mutating.new,
		Quicksilver.new,
		Whip.new
	]
	end
	def self.character_name
		'kehrolyn'
	end
end
