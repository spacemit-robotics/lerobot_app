#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="${SROBOTIS_SDK_ROOT:-$(cd "$SCRIPT_DIR/../../../.." && pwd)}"
cd "$SCRIPT_DIR/.."

model_url="${LEROBOT_ACT_MODEL_URL:-https://archive.spacemit.com/spacemit-ai/model_zoo/vla/act/so101_act_pick_green_cube_amp.tar.gz}"
artifact_dir="${SROBOTIS_TEST_ARTIFACT_DIR:-${SROBOTIS_OUTPUT_ROOT:-$REPO_ROOT/output}/test-artifacts/lerobot_app/${SROBOTIS_TEST_NAME:-act-dummy-inference}}"
cache_dir="${LEROBOT_ACT_MODEL_CACHE:-$REPO_ROOT/output/test-artifacts/lerobot_app/.model_cache}"
archive_path="$cache_dir/so101_act_pick_green_cube_amp.tar.gz"
extract_dir="$cache_dir/extracted"
log_file="$artifact_dir/act_dummy_inference.log"
model_path="$extract_dir/so101_act_pick_green_cube_amp/checkpoints/100000/pretrained_model"

mkdir -p "$artifact_dir" "$cache_dir" "$extract_dir"

echo "[lerobot-app-act-dummy] Downloading ACT model from: $model_url"
if [[ ! -s "$archive_path" ]]; then
  if command -v curl >/dev/null 2>&1; then
    curl -L --fail --retry 3 --connect-timeout 20 -o "$archive_path" "$model_url"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$archive_path" "$model_url"
  else
    echo "Neither curl nor wget is available for model download" >&2
    exit 1
  fi
else
  echo "[lerobot-app-act-dummy] Reusing cached archive: $archive_path"
fi

echo "[lerobot-app-act-dummy] Extracting model archive..."
if [[ ! -d "$model_path" ]]; then
  tar -xzf "$archive_path" -C "$extract_dir"
else
  echo "[lerobot-app-act-dummy] Reusing extracted model: $model_path"
fi

if [[ ! -d "$model_path" ]]; then
  echo "Expected pretrained model directory not found: $model_path" >&2
  find "$extract_dir" -maxdepth 5 -type d | sort >&2
  exit 1
fi

for required_file in config.json model.safetensors policy_preprocessor.json policy_postprocessor.json; do
  if [[ ! -f "$model_path/$required_file" ]]; then
    echo "Required ACT model file is missing: $model_path/$required_file" >&2
    exit 1
  fi
done

echo "[lerobot-app-act-dummy] Running dummy ACT inference benchmark..."
python tests/benchmark_act_dummy_inference.py \
  --model-path "$model_path" \
  --device cpu \
  --warmup "${LEROBOT_ACT_WARMUP:-1}" \
  --iters "${LEROBOT_ACT_ITERS:-1}" \
  2>&1 | tee "$log_file"

if ! grep -q "=== Inference latency" "$log_file"; then
  echo "Inference latency summary was not found in benchmark output" >&2
  exit 1
fi

if ! grep -q "=== Model output types" "$log_file"; then
  echo "Model output description was not found in benchmark output" >&2
  exit 1
fi

if ! grep -q "Top 20 torch ops by self time" "$log_file"; then
  echo "Torch profiler output was not found in benchmark output" >&2
  exit 1
fi

echo "[lerobot-app-act-dummy] ACT model download and dummy inference are validated."
