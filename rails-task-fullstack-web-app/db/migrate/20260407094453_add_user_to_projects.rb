class AddUserToProjects < ActiveRecord::Migration[8.1]
  def up
    # null: true で追加してバックフィル後に NOT NULL 制約を付ける
    add_reference :projects, :user, null: true, foreign_key: true

    # 既存プロジェクトを最初のユーザーに紐付ける（存在する場合）
    first_user_id = execute("SELECT id FROM users ORDER BY id LIMIT 1").first&.fetch("id", nil)
    if first_user_id
      execute("UPDATE projects SET user_id = #{first_user_id} WHERE user_id IS NULL")
    end

    change_column_null :projects, :user_id, false
  end

  def down
    remove_reference :projects, :user, foreign_key: true
  end
end
