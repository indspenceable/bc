require "character"
require "bases"

class Anathema < Style
    def initialize
        super("anathema", 0, -1, -1)
    end
    def reveal!(me)
        # +1 power, +1 pri per token anted (up to 3)
        if (me.current_tokens.count >= 3)
            me.anathema_bonus = 3
        else
            me.anathema_bonus = (me.current_tokens.count)
        end
    end
end

class Darkheart < Style
    def initialize
        super("darkheart", 0, 0, -1)
    end
    def on_hit!
        {
            "gain_life" => ->(me, inputs) {me.gain_life!(2)},
            "discard_token" => ->(me, inputs) {
                select_from_methods(discard_token: me.opponent.token_names).call(me.opponent, inputs)
            }
        }
    end
end

class Pactbond < Style
    def initialize
        super("pactbond", 0, -1, -1)
    end
    def reveal!(me)
        if (me.current_tokens.count >= 2)
            me.gain_life!(2)
        else
        	me.gain_life!(me.current_tokens.count)
        end
    end
    def end_of_beat!
        {
            "free_token" => ->(me, inputs) {
                select_from_methods(free_token: %w(almighty endless immortality inevitable corruption)).call(me, inputs)
            }
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
            "power" => ->(me, inputs) {
                select_from_methods(necrotizing_power: 0..3).call(me, inputs)
            }
        }
    end
end

class Accursed < Style
    def initialize
        super("accursed", 0..1, -1, 0)
    end
    def reveal!(me)
        #gain stun immunity if anted 3 or more tokens
        if (me.current_tokens.count >= 3)
            me.accursed_stun_immunity = true
            me.log_me!("gains stun immunity (Accursed)")
        end
    end
end

class Bloodlight < Base
    def initialize
        super("bloodlight", 1..3, 2, 3)
    end
    def on_damage!
        {
            # gain life per damage dealt, up to the number of tokens anted this turn
            "health_recovery" => ->(me, inputs) {
                if me.damage_dealt_this_beat <= me.current_tokens.count
                    life_recovered = (me.damage_dealt_this_beat)
                else
                    life_recovered = (me.current_tokens.count)
                end
                print ("life recovered " + life_recovered.to_s)
                if life_recovered > 0
                    gain_life!(life_recovered)
                end
            }
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
        super("endless", 0, 0, 2)
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
        {
            "altazziar_lose_life" => ->(me, inputs) {
                me.lose_life!(@life - 1)
            }
            # TODO add the doubling effect of tokens
        }
    end
end

class SealThePact < Finisher
    def initialize
        super("sealthepact", nil, nil, 0)
    end
    def soak
        2
    end
    def after_activating
        {
            "sealthepact_ante_opponent_life" => ->(me, inputs) {me.ante_opponent_life = true}
        }
    end
end


class Hepzibah < Character
    attr_accessor :ante_opponent_life, :current_tokens, :pactbond_free_token, :anathema_bonus, :accursed_stun_immunity
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
        @ante_opponent_life = false
        @used_opponent_life = false
        @pactbond_free_token = nil
        @necrotizing_power = 0
        @anathema_bonus = 0
        @accursed_stun_immunity = false
    end

    def finishers
        [Altazziar.new, SealThePact.new]
    end

    # used to reset the free token each round
    def reveal!
        super
        @pactbond_free_token = nil
    end

    def effect_sources
        super + @current_tokens
    end

    def ante_options
        ((@life > 1) ? @token_pool.map(&:name) : []) + super
    end

    def ante?(choice)
        return true if super
        return true if @pactbond_free_token == choice
        return true if life > 1
        false
    end

    def ante!(choice)
        if choice == "pass"
            log_me!("passes.")
            return
        end
        return if super
        log_me!("antes #{@token_pool.find{ |token| token.name == choice }.name_and_effect}")
        @current_tokens += @token_pool.reject{ |token| token.name != choice }
        @token_pool.delete_if{ |token| token.name == choice }
        if choice == @pactbond_free_token
            log_me!("does not lose life (Pactbond)")
            return
        elsif (@ante_opponent_life && !@used_opponent_life)
            opponent.lose_life!(1)
            @used_opponent_life = true
        else
            lose_life!(1)
        end
    end

    def free_token?(choice)
        %w(almighty endless immortality inevitable corruption).any?{|token_name| choice == token_name}
    end

    def free_token!(choice)
        @pactbond_free_token = choice
    end

    def necrotizing_power?(choice)
        ((life - Integer(choice)) > 0) && (Integer(choice) <= 3)
    end

    def necrotizing_power!(choice)
        log_me!("loses #{choice} life to gain #{choice} power")
        @necrotizing_power = Integer(choice)
        lose_life!(Integer(choice))
    end

    def power
        @necrotizing_power + @anathema_bonus + super
    end

    def priority
        @anathema_bonus + super
    end

    def stun_immunity?
        @accursed_stun_immunity || super
    end

    def discard_token!(choice)
    end

    def discard_token?(choice)
    	false
    end
    def recycle!
        super
        @used_opponent_life = false
        @necrotizing_power = 0
        @anathema_bonus = 0
        @accursed_stun_immunity = false
        @token_pool += @current_tokens
        @current_tokens = []
    end
end
