class AddUserToProjects < ActiveRecord::Migration[8.1]
  def change
    add_reference :projects, :user, foreign_key: true
  end
end
