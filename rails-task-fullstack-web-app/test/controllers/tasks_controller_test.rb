require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @project = projects(:one)
    @task = tasks(:one)
    log_in_as(@user)
  end

  test "should redirect index to project" do
    get project_tasks_url(@project)
    assert_response :redirect
  end

  test "should get new" do
    get new_project_task_url(@project)
    assert_response :success
  end

  test "should create task" do
    assert_difference("Task.count") do
      post project_tasks_url(@project), params: { task: { start_date: @task.start_date, end_date: @task.end_date, status: "not_started", title: "New task" } }
    end

    assert_redirected_to project_url(@project)
  end

  test "should show task" do
    get project_task_url(@project, @task)
    assert_response :success
  end

  test "should get edit" do
    get edit_project_task_url(@project, @task)
    assert_response :success
  end

  test "should update task" do
    patch project_task_url(@project, @task), params: { task: { start_date: @task.start_date, end_date: @task.end_date, status: "in_progress", title: @task.title } }
    assert_redirected_to project_task_url(@project, @task)
  end

  test "should destroy task" do
    assert_difference("Task.count", -1) do
      delete project_task_url(@project, @task)
    end

    assert_redirected_to project_url(@project)
  end
end
