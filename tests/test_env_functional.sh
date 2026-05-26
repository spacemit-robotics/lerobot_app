#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

artifact_dir="${SROBOTIS_TEST_ARTIFACT_DIR:-${SROBOTIS_OUTPUT_ROOT:-$PWD/output}/test-artifacts/lerobot_app/${SROBOTIS_TEST_NAME:-env}}"
mkdir -p "$artifact_dir"
log_file="$artifact_dir/env_functional.log"
exec > >(tee "$log_file") 2>&1

echo "[lerobot-app-env] Checking Python runtime and core imports..."
python - <<'PY'
import importlib
import sys
from pathlib import Path

if sys.version_info < (3, 12):
    raise SystemExit(f"Python >= 3.12 is required by lerobot_app, got {sys.version.split()[0]}")

required_modules = [
    "torch",
    "lerobot",
    "lerobot.policies.act.modeling_act",
    "lerobot.utils.constants",
]
for module_name in required_modules:
    importlib.import_module(module_name)

import torch
from lerobot.policies.act.modeling_act import ACTPolicy
from lerobot.utils.constants import OBS_IMAGES, OBS_STATE

tensor = torch.tensor([1.0, 2.0, 3.0], dtype=torch.float32)
result = torch.sum(tensor * 2).item()
if result != 12.0:
    raise AssertionError(f"Unexpected torch tensor result: {result}")

if not callable(getattr(ACTPolicy, "from_pretrained", None)):
    raise AssertionError("ACTPolicy.from_pretrained is not callable")

if not isinstance(OBS_STATE, str) or not isinstance(OBS_IMAGES, str):
    raise AssertionError("LeRobot observation constants are not strings")

# Verify project structure (cwd is lerobot_app root, set by cd above)
_project_root = Path.cwd()

pyproject = _project_root / "pyproject.toml"
if not pyproject.exists():
    raise AssertionError(f"pyproject.toml is missing from lerobot_app root ({_project_root})")

benchmark = _project_root / "tests" / "benchmark_act_dummy_inference.py"
if not benchmark.exists():
    raise AssertionError(f"ACT dummy benchmark script is missing from {_project_root}/tests")

print("python_version=", sys.version.split()[0])
print("torch_version=", torch.__version__)
print("act_policy_loader=ok")
print("tensor_math=ok")
PY