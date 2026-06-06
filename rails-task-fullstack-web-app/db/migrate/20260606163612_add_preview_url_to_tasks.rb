class AddPreviewUrlToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :preview_url, :string
  end
end
