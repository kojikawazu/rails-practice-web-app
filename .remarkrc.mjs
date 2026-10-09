// リンク切れチェック（remark-validate-links）の設定。
// CI（.github/workflows/ci.yml の link-check ジョブ）とローカル（make lint-links）で
// 同じ設定・同じコマンド（npm run lint:links）を使う。バージョンはルートの package.json /
// package-lock.json で固定する。
//
// 検査するのはリポジトリ内のリンクだけ（相対パスのファイル・見出しアンカー）。
// 別ファイルの見出し（other.md#heading）や md 以外のファイル（docs → app/**/*.rb）も検証する。
// 外部 URL は検査しない（レート制限・一時的な不調で、無関係な PR が落ちるため）。
//
// 対象外のパスは .remarkignore に置く。
import remarkValidateLinks from "remark-validate-links";

export default {
  plugins: [remarkValidateLinks],
};
