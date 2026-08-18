#!/usr/bin/env bash
# Build, unit tests and coverage gate for oficina-mecanico-ios.
set -euo pipefail

THRESHOLD="${COVERAGE_THRESHOLD:-90}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SCHEME="${XCODE_SCHEME:-TodoList}"
DESTINATION="${XCODE_DESTINATION:-platform=iOS Simulator,name=iPhone 17}"
RESULT_BUNDLE="$ROOT/build/TestResults.xcresult"

echo "▶ xcodebuild build"
xcodebuild build \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -quiet

rm -rf "$RESULT_BUNDLE"
mkdir -p "$ROOT/build"

echo "▶ xcodebuild test (TodoListTests only)"
xcodebuild test \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -only-testing:TodoListTests \
  -enableCodeCoverage YES \
  -resultBundlePath "$RESULT_BUNDLE" \
  -quiet

echo "▶ cobertura (escopo testável)"
python3 - "$RESULT_BUNDLE" "$THRESHOLD" <<'PY'
import json
import subprocess
import sys

bundle, threshold = sys.argv[1], float(sys.argv[2])
include_prefixes = (
    "/ViewModels/",
    "/Services/",
    "/Models/",
    "/Utils/",
)
exclude_suffixes = ("Tests.swift", "+Preview.swift")

proc = subprocess.run(
    ["xcrun", "xccov", "view", "--report", "--json", bundle],
    capture_output=True,
    text=True,
    check=True,
)
data = json.loads(proc.stdout)

covered = 0
total = 0
for target in data.get("targets", []):
    if target.get("name") != "TodoList.app":
        continue
    for file in target.get("files", []):
        path = file.get("path", "")
        if not any(p in path for p in include_prefixes):
            continue
        if path.endswith(exclude_suffixes):
            continue
        for fn in file.get("functions", []):
            covered += fn.get("coveredLines", 0)
            total += fn.get("executableLines", 0)

if total == 0:
    print("❌ Nenhuma linha no escopo de cobertura. Veja docs/QUALIDADE.md")
    sys.exit(1)

pct = 100.0 * covered / total
if pct < threshold:
    print(f"❌ Cobertura {pct:.1f}% abaixo de {threshold:.0f}%. Veja docs/QUALIDADE.md")
    sys.exit(1)

print(f"✅ Build, testes e cobertura OK ({pct:.1f}%)")
PY
