# プロジェクトの CRUD と確認画面フローを扱うコントローラー。
# 操作対象は常に current_user のプロジェクトに限定する（他ユーザーのリソースは find で 404）。
#
# 新規作成の確認画面のみ PRG（Post/Redirect/Get）方式（confirm_new）で、
# それ以外（編集・複製）は従来の POST 描画方式を用いる。
class ProjectsController < ApplicationController
  before_action :require_login
  before_action :set_project, only: %i[show edit update destroy]

  # プロジェクト一覧を表示する。
  #
  # @return [void] current_user のプロジェクトを index ビューへ渡す
  def index
    @projects = ProjectService.list(current_user)
  end

  # プロジェクト詳細（配下のタスク一覧を含む）を表示する。
  #
  # @return [void] @project.tasks を show ビューへ渡す
  def show
    @tasks = @project.tasks
  end

  # 新規作成フォームを表示する。
  # 「修正する」(restore=1) 経由は session の入力値を復元、通常の新規は session を破棄して空フォーム。
  #
  # @return [void] @project を組み立てて new ビューを描画
  def new
    # 「修正する」(restore=1) 経由は session の入力値を復元、通常の新規は session を破棄して空フォーム。
    if params[:restore].present?
      @project = current_user.projects.build(pending_project_params)
    else
      reset_pending_project
      @project = current_user.projects.build
    end
  end

  # 編集フォームを表示する。
  #
  # @return [void] set_project で取得済みの @project で edit ビューを描画
  def edit
  end

  # 複製。複製元の値を初期入力した新規作成フォームを表示する（DB は変更しない）。
  # 以降は通常の confirm → create フローに合流する。
  #
  # @return [void] 複製元の値を入れた @project で new ビューを描画
  def duplicate
    source = current_user.projects.find(params[:id])
    @project = current_user.projects.build(title: "#{source.title}のコピー", description: source.description)
    flash.now[:notice] = "「#{source.title}」を複製しました。内容を確認して作成してください。"
    render :new
  end

  # 確認画面。DB には保存せず検証のみ行う。
  # - 新規: (b案2) リダイレクト方式。confirm_new に委譲。
  # - 編集: 従来の POST 描画方式（変更なし）。
  #
  # @return [void] 新規は confirm_new へ委譲／編集は confirm・edit のいずれかを描画
  def confirm
    return confirm_new unless params[:id]

    @project = current_user.projects.find(params[:id])
    @project.assign_attributes(project_params)

    # 確認画面の「修正する」押下時は入力フォームへ戻す（入力値は保持）。
    return render(:edit) if params[:back].present?

    if @project.valid?
      render :confirm
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # 新規作成の確定。DB へ保存し、成功時は退避した session をクリアする。
  #
  # @return [void] 成功: 詳細へリダイレクト／失敗: new を 422 で再描画
  def create
    @project = ProjectService.create(current_user, project_params)

    if @project.persisted?
      reset_pending_project
      redirect_to @project, notice: "プロジェクトを作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # プロジェクトを更新する。
  #
  # @return [void] 成功: 詳細へ 303 リダイレクト／失敗: edit を 422 で再描画
  def update
    if ProjectService.update(@project, project_params)
      redirect_to @project, notice: "プロジェクトを更新しました。", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # プロジェクトを削除する（配下のタスクも連動削除）。
  #
  # @return [void] 一覧へ 303 リダイレクト
  def destroy
    ProjectService.destroy(@project)
    redirect_to projects_path, notice: "プロジェクトを削除しました。", status: :see_other
  end

  private

  # 新規プロジェクトの確認画面（(b案2) リダイレクト方式 / PRG）。
  # POST     : 検証 → 入力値を session に退避 → confirm(GET) へ 303 リダイレクト（Turbo Drive 対応）。
  # GET/HEAD : session から復元して確認画面を描画。session が無ければ new へ戻す（リロード安全網）。
  #
  # 判定は「読み取りかどうか」ではなく **書き込み（POST）かどうか**で行う。
  # Rails は HEAD を GET ルートへ配送するが `request.get?` は HEAD で false になるため、
  # GET を条件にすると HEAD が POST 分岐へ落ち、Strong Parameters 不足で 400 になる。
  #
  # @return [void] GET/HEAD: confirm 描画 or new へリダイレクト／POST: confirm(GET) へ 303 or new（422）
  def confirm_new
    unless request.post?
      return redirect_to(new_project_path, alert: "確認画面の情報がありません。入力し直してください。") if pending_project_params.blank?

      @project = current_user.projects.build(pending_project_params)
      return render :confirm
    end

    @project = current_user.projects.build(project_params)
    if @project.valid?
      session[:pending_project] = project_params.to_h
      redirect_to confirm_projects_path, status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  # session に退避した新規プロジェクトの入力値（許可カラムのみ）。
  #
  # @return [Hash] title / description のみを含むハッシュ（未退避なら空）
  def pending_project_params
    (session[:pending_project] || {}).slice("title", "description")
  end

  # 新規作成のために退避していた session の入力値を破棄する。
  #
  # @return [void]
  def reset_pending_project
    session.delete(:pending_project)
  end

  # URL の :id から current_user のプロジェクトを取得して @project に設定する。
  # 他ユーザー・存在しない id は RecordNotFound（＝404）になる。
  #
  # @return [void]
  # @raise [ActiveRecord::RecordNotFound] 他ユーザーのリソース・存在しない id
  def set_project
    @project = current_user.projects.find(params[:id])
  end

  # Strong Parameters。プロジェクトの許可カラムのみを抽出する。
  #
  # @return [ActionController::Parameters] title / description
  def project_params
    params.require(:project).permit(:title, :description)
  end
end
