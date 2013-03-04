module GamesHelper
  def game_badges(game)
    badges = {}
    badges["Input Required"] = :info if game.play.required_input[game.player_id(current_user)]
    badges
  end
  def character_badges(character_name)
    badges = {}
    badges["Beta"] = :warning if ['khadath', 'rukyuk'].include?(character_name)
    badges
  end

  def badges(badges)
    badges.map do |badge, color|
      content_tag(:span, class: "label label-#{color}"){ badge }
    end.join("").html_safe
  end
end
