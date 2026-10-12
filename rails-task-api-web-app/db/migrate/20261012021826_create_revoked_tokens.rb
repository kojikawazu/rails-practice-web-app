class CreateRevokedTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :revoked_tokens do |t|
      t.string :jti, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end
    # 認証のたびに jti で照合するため一意インデックスを張る（同時ログアウトの重複記録も DB で防ぐ）。
    add_index :revoked_tokens, :jti, unique: true
    # ログアウト時に期限切れの行を範囲指定で消すため。
    add_index :revoked_tokens, :expires_at
  end
end
