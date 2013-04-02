class CreateChallenges < ActiveRecord::Migration
  def change
    create_table :challenges do |t|
      t.integer :from_id
      t.integer :to_id
      t.text :configs

      t.timestamps
    end
  end
end
