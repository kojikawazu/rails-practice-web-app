// CI の変更分類（.github/workflows/ci.yml の changes ジョブ）を検証するスクリプト。
//
// 代表パスの期待判定はこのファイルが正本で、ci.yml のフィルタ定義を読み込んで突き合わせる
// （期待表をコメントとして二重に持つと、片方だけ直されて乖離するため）。
// 判定は paths-filter と同じ picomatch で行い、predicate-quantifier の意味も揃える。
//   every -> すべてのパターンに一致したファイルだけが対象（＝除外リスト方式）
//   some  -> いずれかのパターンに一致したファイルが対象（既定）
import fs from "node:fs";
import path from "node:path";
import * as yaml from "js-yaml";
import picomatch from "picomatch";

const WORKFLOW = path.join(process.cwd(), ".github/workflows/ci.yml");

// [パス, code の期待値, docs の期待値, workflows の期待値]
// code=true -> 静的解析・セキュリティ検査とテスト（Lint & Security / Test / System :js）、docs=true -> Markdown lint、
// workflows=true -> actionlint が動く。
// ドキュメント・ルール以外は未知のパスもテストへ流す（安全側に倒す）ことを固定する。
// workflows は actionlint の検査対象（.github/workflows/*.{yml,yaml}）と、検査器のバージョンを持つ Makefile に限る。
const EXPECTATIONS = [
  ["rails-task-fullstack-web-app/app/models/task.rb", true, false, false],
  ["rails-task-api-web-app/app/controllers/application_controller.rb", true, false, false],
  ["rails-task-fullstack-web-app/spec/models/task_spec.rb", true, false, false],
  ["rails-task-fullstack-web-app/Gemfile.lock", true, false, false],
  ["rails-task-fullstack-web-app/README.md", false, true, false],
  ["rails-task-api-web-app/app/models/AGENTS.md", false, true, false],
  ["docs/03-functional-specification.md", false, true, false],
  ["docs/screenshots/login.png", false, true, false],
  [".claude/rules/github-actions.md", false, true, false],
  ["README.md", false, true, false],
  ["CLAUDE.md", false, true, false],
  ["AGENTS.md", false, true, false],
  [".markdownlint-cli2.jsonc", false, true, false],
  [".remarkrc.mjs", false, true, false],
  [".remarkignore", false, true, false],
  ["package.json", true, true, false],
  ["package-lock.json", true, true, false],
  [".github/workflows/ci.yml", true, false, true],
  [".github/workflows/release.yaml", true, false, true],
  [".github/workflows/AGENTS.md", false, true, false],
  [".github/scripts/verify-path-filters.mjs", true, false, false],
  [".github/dependabot.yml", true, false, false],
  ["Makefile", true, false, true],
  ["docker-compose.yml", true, false, false],
  [".env.example", true, false, false],
  ["scripts/new_tool.sh", true, false, false],
  ["terraform/main.tf", true, false, false],
];

// ci.yml の changes ジョブから、指定 id の paths-filter ステップの定義を取り出す。
function filterOf(steps, id) {
  const step = steps.find((s) => s.id === id);
  if (!step) throw new Error(`changes ジョブに id: ${id} の paths-filter ステップがありません`);
  const definitions = yaml.load(step.with.filters);
  const patterns = definitions[id];
  if (!patterns) throw new Error(`フィルタ ${id} の定義が見つかりません`);
  return { patterns, every: step.with["predicate-quantifier"] === "every" };
}

function matches({ patterns, every }, file) {
  const results = patterns.map((pattern) => picomatch(pattern, { dot: true })(file));
  return every ? results.every(Boolean) : results.some(Boolean);
}

const workflow = yaml.load(fs.readFileSync(WORKFLOW, "utf8"));
const steps = workflow.jobs.changes.steps;
const FILTERS = ["code", "docs", "workflows"];
const filters = FILTERS.map((id) => filterOf(steps, id));

let failed = 0;
const rows = EXPECTATIONS.map(([file, ...expected]) => {
  const actual = filters.map((filter) => matches(filter, file));
  const ok = actual.every((value, i) => value === expected[i]);
  if (!ok) failed += 1;
  return { ok, file, actual, expected };
});

const format = (values) => FILTERS.map((id, i) => `${id}=${String(values[i]).padEnd(5)}`).join(" ");
for (const row of rows) {
  const detail = row.ok ? "" : `  <- 期待 ${format(row.expected)}`;
  console.log(`${row.ok ? "OK " : "NG "} ${row.file.padEnd(60)} ${format(row.actual)}${detail}`);
}

// すべてのパスが最低 1 つの検証に割り当てられていること（何も動かない変更を作らない）。
const orphans = rows.filter((row) => !row.actual.some(Boolean)).map((row) => row.file);
if (orphans.length > 0) {
  failed += orphans.length;
  console.log(`\nどのジョブにも割り当てられないパス: ${orphans.join(", ")}`);
}

if (failed > 0) {
  console.log(`\n${failed} 件が期待と一致しません。ci.yml のフィルタか、このスクリプトの期待表を見直してください。`);
  process.exit(1);
}
console.log(`\n${rows.length} 件すべて期待どおりに分類されました。`);
