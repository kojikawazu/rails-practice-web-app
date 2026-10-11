require 'rails_helper'

# 形と code ごとの応答は request spec（spec/requests/api/v1/error_responses_spec.rb）で固定する。
# ここでは HTTP を通さないと確かめにくい「仕様外の code を返さない」ことだけを検証する。
RSpec.describe ErrorSerializer do
  it "一覧に無い code は例外にし、仕様外の code を返さない" do
    expect { described_class.render(:unknown_code) }.to raise_error(ArgumentError, /unknown_code/)
  end
end
