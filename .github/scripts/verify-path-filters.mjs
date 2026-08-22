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

// [パス, code の期待値, docs の期待値]
// code=true -> テスト（Test / System :js）、docs=true -> Markdown lint が動く。
// ドキュメント・ルール以外は未知のパスもテストへ流す（安全側に倒す）ことを固定する。
const EXPECTATIONS = [
  ["rails-task-fullstack-web-app/app/models/task.rb", true, false],
  ["rails-task-api-web-app/app/controllers/application_controller.rb", true, false],
  ["rails-task-fullstack-web-app/spec/models/task_spec.rb", true, false],
  ["rails-task-fullstack-web-app/Gemfile.lock", true, false],
  ["rails-task-fullstack-web-app/README.md", false, true],
  ["rails-task-api-web-app/app/models/AGENTS.md", false, true],
  ["docs/03-functional-specification.md", false, true],
  ["docs/screenshots/login.png", false, true],
  [".claude/rules/github-actions.md", false, true],
  ["README.md", false, true],
  ["CLAUDE.md", false, true],
  ["AGENTS.md", false, true],
  [".markdownlint-cli2.jsonc", false, true],
  [".github/workflows/ci.yml", true, false],
  [".github/scripts/verify-path-filters.mjs", true, false],
  ["Makefile", true, false],
  ["docker-compose.yml", true, false],
  [".env.example", true, false],
  ["scripts/new_tool.sh", true, false],
  ["terraform/main.tf", true, false],
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
const code = filterOf(steps, "code");
const docs = filterOf(steps, "docs");

let failed = 0;
const rows = EXPECTATIONS.map(([file, expectedCode, expectedDocs]) => {
  const actualCode = matches(code, file);
  const actualDocs = matches(docs, file);
  const ok = actualCode === expectedCode && actualDocs === expectedDocs;
  if (!ok) failed += 1;
  return { ok, file, actualCode, actualDocs, expectedCode, expectedDocs };
});

for (const row of rows) {
  const detail = row.ok ? "" : `  <- 期待 code=${row.expectedCode} docs=${row.expectedDocs}`;
  console.log(`${row.ok ? "OK " : "NG "} ${row.file.padEnd(60)} code=${String(row.actualCode).padEnd(5)} docs=${row.actualDocs}${detail}`);
}

// すべてのパスが最低 1 つの検証に割り当てられていること（何も動かない変更を作らない）。
const orphans = rows.filter((row) => !row.actualCode && !row.actualDocs).map((row) => row.file);
if (orphans.length > 0) {
  failed += orphans.length;
  console.log(`\nどのジョブにも割り当てられないパス: ${orphans.join(", ")}`);
}

if (failed > 0) {
  console.log(`\n${failed} 件が期待と一致しません。ci.yml のフィルタか、このスクリプトの期待表を見直してください。`);
  process.exit(1);
}
console.log(`\n${rows.length} 件すべて期待どおりに分類されました。`);
