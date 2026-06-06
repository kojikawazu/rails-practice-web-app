class ReplaceDueDateWithStartEndDateOnTasks < ActiveRecord::Migration[8.1]
  # 期日(due_date)を廃止し、作業期間(start_date / end_date)へ置き換える。
  # ロールバック時に due_date を復元できるよう up/down を明示する。
  def up
    add_column :tasks, :start_date, :date
    add_column :tasks, :end_date, :date
    remove_column :tasks, :due_date
  end

  def down
    add_column :tasks, :due_date, :date
    remove_column :tasks, :start_date
    remove_column :tasks, :end_date
  end
end
