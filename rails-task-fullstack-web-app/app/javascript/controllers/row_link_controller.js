import { Controller } from "@hotwired/stimulus"

// 一覧の行全体をクリックで詳細へ遷移させる。
//
// 以前は tr の onclick 属性で location.href を設定していたが、CSP（script-src に
// unsafe-inline を許可しない）ではインラインハンドラが実行されないため Stimulus へ移した。
//
// 行内のリンク・ボタンは本来の遷移を優先する。従来は各リンクに
// onclick="event.stopPropagation()" を付けていたが、行側で 1 箇所判定する形に集約した
// （リンクを追加するたびに抑止を書き忘れる余地を無くすため）。
export default class extends Controller {
  static values = { url: String }

  navigate(event) {
    if (event.target.closest("a, button, input, label")) return

    window.location.href = this.urlValue
  }
}
