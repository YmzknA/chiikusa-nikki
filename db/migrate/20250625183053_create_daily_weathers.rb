class CreateDailyWeathers < ActiveRecord::Migration[7.2]
  def change
    create_table :daily_weathers do |t|
      t.date :date
      t.jsonb :data

      t.timestamps
    end
    add_index :daily_weathers, :date, unique: true
  end
end
