class CreateStudents < ActiveRecord::Migration
  def change
    create_table :students do |t|
      t.string :user_name
      t.string :access_token 

      t.timestamps null: false
    end
  end
end
