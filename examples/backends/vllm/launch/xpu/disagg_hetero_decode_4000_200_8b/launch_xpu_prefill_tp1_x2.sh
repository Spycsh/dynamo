#!/bin/bash
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# Frontend + two XPU prefill workers, each TP1.

set -e
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/../../../../../common/launch_utils.sh"
trap dynamo_exit_trap EXIT

export PYTHONHASHSEED=0
export PYTHONPATH="${PYTHONPATH:-/workspace/vllm:/opt/venv/lib/python3.12/site-packages}"
export DYN_DECODE_NON_CPU_TO_CPU_RATIO="${DYN_DECODE_NON_CPU_TO_CPU_RATIO:-16}"

MODEL="${MODEL:-/date/hf_models/Qwen3-8B/}"
BLOCK_SIZE="${BLOCK_SIZE:-64}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-8192}"
TP_SIZE="${TP_SIZE:-1}"
KV_TRANSFER_CONFIG='{"kv_connector":"NixlConnector","kv_role":"kv_both","kv_buffer_device":"xpu","kv_connector_extra_config":{"enforce_handshake_compat": false}}'
KV_EVENTS_CONFIG_0='{"publisher":"zmq","topic":"kv-events","endpoint":"tcp://*:5558", "enable_kv_cache_events":true}'
KV_EVENTS_CONFIG_1='{"publisher":"zmq","topic":"kv-events","endpoint":"tcp://*:5560", "enable_kv_cache_events":true}'

HTTP_PORT="${DYN_HTTP_PORT:-8000}"
XPU_PREFILL_0_DEVICES="${XPU_PREFILL_0_DEVICES:-4}"
XPU_PREFILL_1_DEVICES="${XPU_PREFILL_1_DEVICES:-5}"
XPU_PREFILL_0_NIXL_PORT="${XPU_PREFILL_0_NIXL_PORT:-20098}"
XPU_PREFILL_1_NIXL_PORT="${XPU_PREFILL_1_NIXL_PORT:-20099}"

python -m dynamo.frontend \
    --router-mode kv \
    --http-port "$HTTP_PORT" &

VLLM_TARGET_DEVICE=xpu \
VLLM_NIXL_SIDE_CHANNEL_PORT="$XPU_PREFILL_0_NIXL_PORT" \
ZE_AFFINITY_MASK="$XPU_PREFILL_0_DEVICES" \
python3 -m dynamo.vllm \
    --model "$MODEL" \
    --block-size "$BLOCK_SIZE" \
    --max-model-len "$MAX_MODEL_LEN" \
    --tensor-parallel-size "$TP_SIZE" \
    --enforce-eager \
    --enable-chunked-prefill \
    --disaggregation-mode prefill \
    --kv-transfer-config "$KV_TRANSFER_CONFIG" \
    --kv-events-config "$KV_EVENTS_CONFIG_0" &

VLLM_TARGET_DEVICE=xpu \
VLLM_NIXL_SIDE_CHANNEL_PORT="$XPU_PREFILL_1_NIXL_PORT" \
ZE_AFFINITY_MASK="$XPU_PREFILL_1_DEVICES" \
python3 -m dynamo.vllm \
    --model "$MODEL" \
    --block-size "$BLOCK_SIZE" \
    --max-model-len "$MAX_MODEL_LEN" \
    --tensor-parallel-size "$TP_SIZE" \
    --enforce-eager \
    --enable-chunked-prefill \
    --disaggregation-mode prefill \
    --kv-transfer-config "$KV_TRANSFER_CONFIG" \
    --kv-events-config "$KV_EVENTS_CONFIG_1" &

wait_any_exit