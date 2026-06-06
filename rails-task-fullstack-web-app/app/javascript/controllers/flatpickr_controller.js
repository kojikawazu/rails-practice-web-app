import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"

// 開始日・終了日の入力欄に flatpickr（日付ピッカー）を適用する。
// ラッパー要素に data-controller="flatpickr" を付け、開始/終了の input を
// それぞれ start / end ターゲットとして参照する。
//
// - dateFormat: "Y-m-d"（サーバー側 date と一致）
// - allowInput: true（手入力可。Capybara の fill_in でも操作できる）
// - 終了日の minDate を開始日に連動させ、終了 >= 開始 を UI でも担保する
export default class extends Controller {
  static targets = ["start", "end"]

  connect() {
    const common = { dateFormat: "Y-m-d", allowInput: true }

    this.endPicker = flatpickr(this.endTarget, common)
    this.startPicker = flatpickr(this.startTarget, {
      ...common,
      onChange: (dates) => {
        this.endPicker.set("minDate", dates[0] || null)
      },
    })

    // 既存値（編集・複製・確認画面からの戻り）がある場合は初期 minDate を反映する。
    if (this.startTarget.value) {
      this.endPicker.set("minDate", this.startTarget.value)
    }
  }

  disconnect() {
    this.startPicker?.destroy()
    this.endPicker?.destroy()
  }
}
