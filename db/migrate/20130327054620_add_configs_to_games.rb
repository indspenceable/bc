class AddConfigsToGames < ActiveRecord::Migration
  def up
    add_column :games, :configs, :text
    Game.reset_column_information
    Game.all.each do |game|
      game.configs = {starting_player: game['starting_player']}
      game.save!
    end
    remove_column :games, :starting_player
  end
  def down
    add_column :games, :starting_player, :boolean
    Game.reset_column_information
    Game.all.each do |game|
      game['starting_player']= game.configs[:starting_player]
      game.save!
    end
    remove_column :games, :configs
  end
end
