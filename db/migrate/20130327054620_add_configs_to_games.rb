class AddConfigsToGames < ActiveRecord::Migration
  def change
    add_column :games, :configs, :text
  end
end