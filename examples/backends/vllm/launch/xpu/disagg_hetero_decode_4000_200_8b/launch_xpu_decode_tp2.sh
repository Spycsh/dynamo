#!/bin/bash
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# One XPU decode worker, TP2.

set -e
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/../../../../../common/launch_utils.sh"
trap dynamo_exit_trap EXIT

export PYTHONHASHSEED=0
export PYTHONPATH="${PYTHONPATH:-/workspace/vllm:/opt/venv/lib/python3.12/site-packages}"

MODEL="${MODEL:-/date/hf_models/Qwen3-8B/}"
BLOCK_SIZE="${BLOCK_SIZE:-64}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-8192}"
TP_SIZE="${TP_SIZE:-2}"
KV_TRANSFER_CONFIG='{"kv_connector":"NixlConnector","kv_role":"kv_both","kv_buffer_device":"xpu","kv_connector_extra_config":{"enforce_handshake_compat": false}}'
KV_EVENTS_CONFIG='{"publisher":"zmq","topic":"kv-events","endpoint":"tcp://*:5556", "enable_kv_cache_events":true}'

XPU_DECODE_DEVICES="${XPU_DECODE_DEVICES:-6,7}"
XPU_DECODE_NIXL_PORT="${XPU_DECODE_NIXL_PORT:-20096}"

VLLM_TARGET_DEVICE=xpu \
VLLM_NIXL_SIDE_CHANNEL_PORT="$XPU_DECODE_NIXL_PORT" \
ZE_AFFINITY_MASK="$XPU_DECODE_DEVICES" \
python3 -m dynamo.vllm \
    --model "$MODEL" \
    --block-size "$BLOCK_SIZE" \
    --max-model-len "$MAX_MODEL_LEN" \
    --tensor-parallel-size "$TP_SIZE" \
    --enforce-eager \
    --disaggregation-mode decode \
    --kv-transfer-config "$KV_TRANSFER_CONFIG" \
    --kv-events-config "$KV_EVENTS_CONFIG" &

wait_any_exit