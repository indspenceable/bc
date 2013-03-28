class AddValidPlayToGames < ActiveRecord::Migration
  def change
    add_column :games, :valid_play, :boolean, default: true
  end
end
