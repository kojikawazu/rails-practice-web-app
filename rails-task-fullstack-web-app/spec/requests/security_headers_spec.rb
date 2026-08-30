require 'rails_helper'

# CSP は XSS 対策の多層防御（入力検証 + 出力エスケープ + CSP）のうち、ブラウザ側の防御。
# 「ヘッダーが付いていること」と「実行可能な資源の制限が緩んでいないこと」を固定する。
RSpec.describe "セキュリティヘッダー（CSP）", type: :request do
  let(:user) { create(:user) }
  let!(:project) { create(:project, user: user) }

  def csp
    response.headers["Content-Security-Policy"]
  end

  before do
    post login_path, params: { email: user.email, password: 'password123' }
    get projects_path
  end

  it "enforce モードの Content-Security-Policy を返す（Report-Only ではない）" do
    expect(csp).to be_present
    expect(response.headers["Content-Security-Policy-Report-Only"]).to be_nil
  end

  it "script-src は自オリジンと nonce だけを許可し、unsafe-inline / unsafe-eval を含まない" do
    expect(csp).to match(/script-src [^;]*'self'/)
    expect(csp).to match(/script-src [^;]*'nonce-/)
    expect(csp).not_to match(/script-src [^;]*'unsafe-inline'/)
    expect(csp).not_to match(/script-src [^;]*'unsafe-eval'/)
  end

  it "object-src / base-uri / frame-ancestors で、プラグイン・base 書き換え・被埋め込みを禁止する" do
    expect(csp).to include("object-src 'none'")
    expect(csp).to include("base-uri 'self'")
    expect(csp).to include("frame-ancestors 'none'")
  end

  # 段階導入: View に残るインライン style 属性のみ許可し、<style> ブロックの注入は禁止したまま。
  # インライン style を CSS へ移行したら style-src-attr ごと外す。
  it "インライン style は属性のみ暫定で許可し、<style> ブロックの注入は許さない" do
    expect(csp).to include("style-src-attr 'unsafe-inline'")
    expect(csp).to match(/style-src [^;]*'self'/)
    expect(csp).not_to match(/style-src [^;]*'unsafe-inline'/)
  end

  it "preview_url のプレビューのため frame-src は http/https に限る（javascript: や data: は許可しない）" do
    expect(csp).to match(/frame-src [^;]*http:/)
    expect(csp).to match(/frame-src [^;]*https:/)
    expect(csp).not_to match(/frame-src [^;]*data:/)
  end

  it "importmap のインライン script には nonce が付き、script-src 'self' のままでも読み込める" do
    expect(response.body).to match(/<script type="importmap"[^>]*nonce="/)
  end
end
