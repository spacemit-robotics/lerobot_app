#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="${SROBOTIS_SDK_ROOT:-$(cd "$SCRIPT_DIR/../../../.." && pwd)}"
cd "$SCRIPT_DIR/.."

model_url="${LEROBOT_ACT_MODEL_URL:-https://archive.spacemit.com/spacemit-ai/model_zoo/vla/act/so101_act_pick_green_cube_amp.tar.gz}"
module_safe_name="application__native__lerobot_app"
artifact_dir="${SROBOTIS_TEST_ARTIFACT_DIR:-${SROBOTIS_OUTPUT_ROOT:-$REPO_ROOT/output}/test/manual/${module_safe_name}/modules/${module_safe_name}}"
cache_dir="${LEROBOT_ACT_MODEL_CACHE:-$REPO_ROOT/output/test/manual/${module_safe_name}/.model_cache}"
archive_path="$cache_dir/so101_act_pick_green_cube_amp.tar.gz"
extract_dir="$cache_dir/extracted"
log_file="$artifact_dir/act_dummy_performance.log"
model_path="$extract_dir/so101_act_pick_green_cube_amp/checkpoints/100000/pretrained_model"
max_avg_ms="${LEROBOT_ACT_MAX_AVG_MS:-10000}"

mkdir -p "$artifact_dir" "$cache_dir" "$extract_dir"

if [[ ! -s "$archive_path" ]]; then
  echo "[lerobot-app-act-perf] Downloading ACT model from: $model_url"
  if command -v curl >/dev/null 2>&1; then
    curl -L --fail --retry 3 --connect-timeout 20 -o "$archive_path" "$model_url"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$archive_path" "$model_url"
  else
    echo "Neither curl nor wget is available for model download" >&2
    exit 1
  fi
fi

if [[ ! -d "$model_path" ]]; then
  lock_file="$cache_dir/.extract.lock"
  (
    flock -x 200
    if [[ ! -d "$model_path" ]]; then
      echo "[lerobot-app-act-perf] Extracting model archive..."
      tar -xzf "$archive_path" -C "$extract_dir"
    fi
  ) 200>"$lock_file"
else
  echo "[lerobot-app-act-perf] Reusing extracted model: $model_path"
fi

if [[ ! -d "$model_path" ]]; then
  echo "Expected pretrained model directory not found: $model_path" >&2
  find "$extract_dir" -maxdepth 5 -type d | sort >&2
  exit 1
fi

echo "[lerobot-app-act-perf] Running ACT dummy inference performance check..."
python tests/benchmark_act_dummy_inference.py \
  --model-path "$model_path" \
  --device cpu \
  --warmup "${LEROBOT_ACT_WARMUP:-3}" \
  --iters "${LEROBOT_ACT_ITERS:-5}" \
  2>&1 | tee "$log_file"

avg_ms="$(awk '/^avg:/ {print $2; exit}' "$log_file")"
if [[ -z "$avg_ms" ]]; then
  echo "Could not parse average inference latency from benchmark output" >&2
  exit 1
fi

python - "$avg_ms" "$max_avg_ms" <<'PY'
import sys

avg_ms = float(sys.argv[1])
max_avg_ms = float(sys.argv[2])
if avg_ms > max_avg_ms:
    raise SystemExit(f"ACT average latency {avg_ms:.3f} ms exceeds threshold {max_avg_ms:.3f} ms")
print(f"act_avg_latency_ms={avg_ms:.3f}")
print(f"act_max_avg_latency_ms={max_avg_ms:.3f}")
PY

echo "[lerobot-app-act-perf] ACT dummy inference performance is within threshold."
