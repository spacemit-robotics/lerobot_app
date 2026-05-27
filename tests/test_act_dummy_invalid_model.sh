#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="${SROBOTIS_SDK_ROOT:-$(cd "$SCRIPT_DIR/../../../.." && pwd)}"
cd "$SCRIPT_DIR/.."

artifact_dir="${SROBOTIS_TEST_ARTIFACT_DIR:-${SROBOTIS_OUTPUT_ROOT:-$REPO_ROOT/output}/test-artifacts/lerobot_app/${SROBOTIS_TEST_NAME:-invalid-model}}"
mkdir -p "$artifact_dir"
missing_model="/tmp/lerobot-app-ci-missing-act-model-$$"
log_file="$artifact_dir/invalid_model.log"
rm -rf "$missing_model"

echo "[lerobot-app-invalid-model] Verifying dummy inference fails fast for a missing model path..."
set +e
python tests/benchmark_act_dummy_inference.py \
  --model-path "$missing_model" \
  --device cpu \
  --warmup 0 \
  --iters 1 \
  >"$log_file" 2>&1
status=$?
set -e

cat "$log_file"

if [[ "$status" -eq 0 ]]; then
  echo "Expected benchmark_act_dummy_inference.py to fail for missing model path, but it exited 0" >&2
  exit 1
fi

if ! grep -Eq "Model path does not exist|FileNotFoundError|No such file|does not exist" "$log_file"; then
  echo "Missing-model failure did not include a clear diagnostic" >&2
  exit 1
fi

echo "[lerobot-app-invalid-model] Missing model path error path is validated."
