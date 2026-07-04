# 全メーラーの基底クラス（Rails 標準）。既定の送信元とレイアウトを定義する。
class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"
  layout "mailer"
end
