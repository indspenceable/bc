class AddStartingPlayerToGames < ActiveRecord::Migration
  def change
    add_column :games, :starting_player, :integer
  end
end
