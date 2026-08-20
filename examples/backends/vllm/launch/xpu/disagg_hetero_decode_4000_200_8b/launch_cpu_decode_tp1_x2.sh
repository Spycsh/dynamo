#!/bin/bash
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# Two CPU decode workers, each TP1.

set -e
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/../../../../../common/launch_utils.sh"
trap dynamo_exit_trap EXIT

export PYTHONHASHSEED=0
export PYTHONPATH="${PYTHONPATH:-/workspace/vllm:/opt/venv/lib/python3.12/site-packages}"

MODEL="${MODEL:-/date/hf_models/Qwen3-8B/}"
BLOCK_SIZE="${BLOCK_SIZE:-64}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-8192}"
TP_SIZE="${TP_SIZE:-1}"
KV_TRANSFER_CONFIG='{"kv_connector":"NixlConnector","kv_role":"kv_both","kv_buffer_device":"cpu","kv_connector_extra_config":{"enforce_handshake_compat": false}}'
KV_EVENTS_CONFIG_0='{"publisher":"zmq","topic":"kv-events","endpoint":"tcp://*:5557", "enable_kv_cache_events":true}'
KV_EVENTS_CONFIG_1='{"publisher":"zmq","topic":"kv-events","endpoint":"tcp://*:5559", "enable_kv_cache_events":true}'

CPU_DECODE_0_NIXL_PORT="${CPU_DECODE_0_NIXL_PORT:-20100}"
CPU_DECODE_1_NIXL_PORT="${CPU_DECODE_1_NIXL_PORT:-20101}"

CUDA_VISIBLE_DEVICES="" \
NVIDIA_VISIBLE_DEVICES=none \
VLLM_TARGET_DEVICE=cpu \
VLLM_NIXL_SIDE_CHANNEL_PORT="$CPU_DECODE_0_NIXL_PORT" \
python3 -m dynamo.vllm \
    --model "$MODEL" \
    --block-size "$BLOCK_SIZE" \
    --max-model-len "$MAX_MODEL_LEN" \
    --tensor-parallel-size "$TP_SIZE" \
    --disaggregation-mode decode \
    --kv-transfer-config "$KV_TRANSFER_CONFIG" \
    --kv-events-config "$KV_EVENTS_CONFIG_0" &

# CUDA_VISIBLE_DEVICES="" \
# NVIDIA_VISIBLE_DEVICES=none \
# VLLM_TARGET_DEVICE=cpu \
# VLLM_NIXL_SIDE_CHANNEL_PORT="$CPU_DECODE_1_NIXL_PORT" \
# python3 -m dynamo.vllm \
#     --model "$MODEL" \
#     --block-size "$BLOCK_SIZE" \
#     --max-model-len "$MAX_MODEL_LEN" \
#     --max-num-seqs "$CPU_MAX_NUM_SEQS" \
#     --max-num-batched-tokens "$CPU_MAX_NUM_BATCHED_TOKENS" \
#     --tensor-parallel-size "$TP_SIZE" \
#     --enforce-eager \
#     --disaggregation-mode decode \
#     --kv-transfer-config "$KV_TRANSFER_CONFIG" \
#     --no-enable-prefix-caching \
#     --kv-events-config "$KV_EVENTS_CONFIG_1" &

wait_any_exit
