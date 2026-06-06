json.extract! task, :id, :title, :status, :start_date, :end_date, :project_id, :created_at, :updated_at
json.url project_task_url(task.project, task, format: :json)
