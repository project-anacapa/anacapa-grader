class CreateStudents < ActiveRecord::Migration
  def change
    create_table :students do |t|
      t.user_name :string
      t.token :string

      t.timestamps null: false
    end
  end
end
