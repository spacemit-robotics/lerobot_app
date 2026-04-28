#!/bin/bash
# Copyright 2026 SpacemiT (Hangzhou) Technology Co. Ltd.
#
# SPDX-License-Identifier: Apache-2.0

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${APP_DIR}/../../.." && pwd)"
VENV_DIR="${REPO_ROOT}/output/envs/lerobot_app"
POLICY_PATH="${APP_DIR}/models/so101_act_pick_green_cube_amp/checkpoints/100000/pretrained_model"
DATASET_RECORD_DIR="${APP_DIR}/datasets/eval_so101_act_pick_green_cube_amp"

if [ ! -d "${VENV_DIR}" ]; then
  bash "${APP_DIR}/scripts/setup_env.sh"
fi

if [ ! -d "${POLICY_PATH}" ]; then
  echo "[pick_cube_record] Policy path not found: ${POLICY_PATH}" >&2
  exit 1
fi

source "${VENV_DIR}/bin/activate"
rm -rf "${DATASET_RECORD_DIR}"
lerobot-record  \
  --robot.type=so101_follower \
  --robot.port=/dev/ttyACM0 \
  --robot.cameras="{
        top:  {type: opencv, index_or_path: 15, width: 640, height: 480, fps: 30, fourcc: MJPG},
        wrist: {type: opencv, index_or_path: 13, width: 640, height: 480, fps: 30, fourcc: MJPG}
    }" \
  --robot.id=my_awesome_follower_arm \
  --display_data=false \
  --dataset.repo_id=annyi/eval_so101_act_pick_green_cube_amp \
  --dataset.root="${DATASET_RECORD_DIR}" \
  --dataset.single_task="Place the green cube into the box" \
  --dataset.vcodec=h264 \
  --policy.path="${POLICY_PATH}" \
  --policy.device=cpu \
  --dataset.num_episodes=1 \
  --dataset.episode_time_s=120 \
  --dataset.reset_time_s=30 \
  --dataset.push_to_hub=false \
  --play_sounds=false \
  "$@"
