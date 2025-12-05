#!/bin/bash
# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
set -e
trap 'echo Cleaning up...; kill 0' EXIT

# Set deterministic hash for KV event IDs
export PYTHONHASHSEED=0

# Common configuration
MODEL="deepseek-ai/DeepSeek-R1-Distill-Llama-8B"
BLOCK_SIZE=64
export VLLM_NIXL_DEVICE_TO_DEVICE=false
export VLLM_SKIP_WARMUP=true           # skip warmup for quick debugging
export PT_HPU_LAZY_MODE=0               # set 1 this for graph mode
export NIXL_BUFFER_DEVICE=cpu
export VLLM_NIXL_BACKEND=UCX                   # can be UCX or OFI
export UCX_TLS="rc,ud,ib"              # rdma

# Start frontend with KV routing
# The frontend will automatically detect prefill workers and activate an internal prefill router
# edit --router-mode to random / round-robin / kv
python -m dynamo.frontend \
    --router-mode kv \
    --http-port 8000 \
    --router-reset-states &

# four decode workers
# --enforce-eager is added for quick deployment. for production use, need to remove this flag
VLLM_NIXL_SIDE_CHANNEL_PORT=20096 \
HABANA_VISIBLE_DEVICES=0 python3 -m dynamo.vllm \
    --model $MODEL \
    --block-size $BLOCK_SIZE \
    --kv-transfer-config "{\"kv_connector\": \"NixlConnector\", \"kv_role\": \"kv_both\", \"kv_buffer_device\": \"${NIXL_BUFFER_DEVICE}\", \"kv_connector_extra_config\": {\"backends\": [\"${VLLM_NIXL_BACKEND}\"]}}" \
    --connector none \
    --kv-events-config '{"publisher":"zmq","topic":"kv-events","endpoint":"tcp://*:5556", "enable_kv_cache_events":true}' &

VLLM_NIXL_SIDE_CHANNEL_PORT=20097 \
HABANA_VISIBLE_DEVICES=1 python3 -m dynamo.vllm \
    --model $MODEL \
    --block-size $BLOCK_SIZE \
    --kv-transfer-config "{\"kv_connector\": \"NixlConnector\", \"kv_role\": \"kv_both\", \"kv_buffer_device\": \"${NIXL_BUFFER_DEVICE}\", \"kv_connector_extra_config\": {\"backends\": [\"${VLLM_NIXL_BACKEND}\"]}}" \
    --connector none \
    --kv-events-config '{"publisher":"zmq","topic":"kv-events","endpoint":"tcp://*:5557", "enable_kv_cache_events":true}' &

VLLM_NIXL_SIDE_CHANNEL_PORT=20102 \
HABANA_VISIBLE_DEVICES=2 python3 -m dynamo.vllm \
    --model $MODEL \
    --block-size $BLOCK_SIZE \
    --kv-transfer-config "{\"kv_connector\": \"NixlConnector\", \"kv_role\": \"kv_both\", \"kv_buffer_device\": \"${NIXL_BUFFER_DEVICE}\", \"kv_connector_extra_config\": {\"backends\": [\"${VLLM_NIXL_BACKEND}\"]}}" \
    --connector none \
    --kv-events-config '{"publisher":"zmq","topic":"kv-events","endpoint":"tcp://*:5562", "enable_kv_cache_events":true}' &

VLLM_NIXL_SIDE_CHANNEL_PORT=20103 \
HABANA_VISIBLE_DEVICES=3 python3 -m dynamo.vllm \
    --model $MODEL \
    --block-size $BLOCK_SIZE \
    --kv-transfer-config "{\"kv_connector\": \"NixlConnector\", \"kv_role\": \"kv_both\", \"kv_buffer_device\": \"${NIXL_BUFFER_DEVICE}\", \"kv_connector_extra_config\": {\"backends\": [\"${VLLM_NIXL_BACKEND}\"]}}" \
    --connector none \
    --kv-events-config '{"publisher":"zmq","topic":"kv-events","endpoint":"tcp://*:5563", "enable_kv_cache_events":true}' &


# four prefill workers
# When registered with --is-prefill-worker, these workers are automatically detected
# by the frontend, which activates an internal prefill router for KV-aware prefill routing
VLLM_NIXL_SIDE_CHANNEL_PORT=20098 \
HABANA_VISIBLE_DEVICES=4 python3 -m dynamo.vllm \
    --model $MODEL \
    --block-size $BLOCK_SIZE \
    --kv-transfer-config "{\"kv_connector\": \"NixlConnector\", \"kv_role\": \"kv_both\", \"kv_buffer_device\": \"${NIXL_BUFFER_DEVICE}\", \"kv_connector_extra_config\": {\"backends\": [\"${VLLM_NIXL_BACKEND}\"]}}" \
    --connector none \
    --is-prefill-worker \
    --kv-events-config '{"publisher":"zmq","topic":"kv-events","endpoint":"tcp://*:5558", "enable_kv_cache_events":true}' &

VLLM_NIXL_SIDE_CHANNEL_PORT=20099 \
HABANA_VISIBLE_DEVICES=5 python3 -m dynamo.vllm \
    --model $MODEL \
    --block-size $BLOCK_SIZE \
    --kv-transfer-config "{\"kv_connector\": \"NixlConnector\", \"kv_role\": \"kv_both\", \"kv_buffer_device\": \"${NIXL_BUFFER_DEVICE}\", \"kv_connector_extra_config\": {\"backends\": [\"${VLLM_NIXL_BACKEND}\"]}}" \
    --connector none \
    --is-prefill-worker \
    --kv-events-config '{"publisher":"zmq","topic":"kv-events","endpoint":"tcp://*:5559", "enable_kv_cache_events":true}' &

VLLM_NIXL_SIDE_CHANNEL_PORT=20100 \
HABANA_VISIBLE_DEVICES=6 python3 -m dynamo.vllm \
    --model $MODEL \
    --block-size $BLOCK_SIZE \
    --kv-transfer-config "{\"kv_connector\": \"NixlConnector\", \"kv_role\": \"kv_both\", \"kv_buffer_device\": \"${NIXL_BUFFER_DEVICE}\", \"kv_connector_extra_config\": {\"backends\": [\"${VLLM_NIXL_BACKEND}\"]}}" \
    --connector none \
    --is-prefill-worker \
    --kv-events-config '{"publisher":"zmq","topic":"kv-events","endpoint":"tcp://*:5560", "enable_kv_cache_events":true}' &

VLLM_NIXL_SIDE_CHANNEL_PORT=20101 \
HABANA_VISIBLE_DEVICES=7 python3 -m dynamo.vllm \
    --model $MODEL \
    --block-size $BLOCK_SIZE \
    --kv-transfer-config "{\"kv_connector\": \"NixlConnector\", \"kv_role\": \"kv_both\", \"kv_buffer_device\": \"${NIXL_BUFFER_DEVICE}\", \"kv_connector_extra_config\": {\"backends\": [\"${VLLM_NIXL_BACKEND}\"]}}" \
    --connector none \
    --is-prefill-worker \
    --kv-events-config '{"publisher":"zmq","topic":"kv-events","endpoint":"tcp://*:5561", "enable_kv_cache_events":true}'
