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

  # インライン style 属性は CSS クラスへ移行済み（#101）。属性は一切許さず、<style> ブロックも
  # nonce の無いもの（＝注入されたもの）は許さず、CSS インジェクションによる情報漏えいの経路を残さない。
  it "style は自オリジンの CSS を許可し、CSP のどこにも unsafe-inline を含まない" do
    expect(csp).to match(/style-src [^;]*'self'/)
    expect(csp).not_to include("style-src-attr")
    expect(csp).not_to include("'unsafe-inline'")
  end

  # Turbo はプログレスバーの <style> に csp_meta_tag の nonce を付けて挿入する（#132）。
  # style-src に nonce が無いとブロックされ、ブラウザのコンソールに CSP 違反が出続ける。
  it "style-src に nonce を含め、Turbo が挿入する <style> を許可する" do
    expect(csp).to match(/style-src [^;]*'nonce-/)
    expect(response.body).to match(/<meta name="csp-nonce" content="[^"]+"/)
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

# CSP が style 属性を許さないため、View にインライン style を書くとエラーにならずブラウザで
# 黙って無視され、画面だけが崩れる。request spec では気づけないので、テンプレートを直接検査する。
RSpec.describe "View のインライン style" do
  it "app/views に style 属性・style: オプションを書かない（CSS クラスを使う）" do
    offenders = Dir[Rails.root.join("app/views/**/*.erb")].flat_map do |path|
      File.readlines(path).each_with_index.filter_map do |line, index|
        "#{Pathname(path).relative_path_from(Rails.root)}:#{index + 1}" if line.match?(/\bstyle\s*[=:]/)
      end
    end
    expect(offenders).to be_empty
  end
end
