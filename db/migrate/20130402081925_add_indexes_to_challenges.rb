class AddIndexesToChallenges < ActiveRecord::Migration
  def change
    add_index :challenges, :from_id
    add_index :challenges, :to_id
    add_index :challenges, [:from_id, :to_id, :inactive]
  end
end
