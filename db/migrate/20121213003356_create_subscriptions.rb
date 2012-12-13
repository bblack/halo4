class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.string :gamertag

      t.timestamps
    end
  end
end
