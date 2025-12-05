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
# VLLM_NIXL_DEVICE_TO_DEVICE=false
VLLM_SKIP_WARMUP=true           # skip warmup for quick debugging
export PT_HPU_LAZY_MODE=0               # set 1 this for graph mode
# NIXL_BUFFER_DEVICE=cpu
# VLLM_NIXL_BACKEND=UCX                   # can be UCX or OFI
# UCX_TLS="rc,ud,ib"              # rdma

# Start frontend with KV routing
# The frontend will automatically detect prefill workers and activate an internal prefill router
# edit --router-mode to random / round-robin / kv
python -m dynamo.frontend \
    --router-mode kv \
    --http-port 8000 \
    --router-reset-states &

# 8 workers
# --enforce-eager is added for quick deployment. for production use, need to remove this flag
HABANA_VISIBLE_DEVICES=0 python3 -m dynamo.vllm \
    --model $MODEL \
    --block-size $BLOCK_SIZE \
    --connector none \
    --kv-events-config '{"publisher":"zmq","topic":"kv-events","endpoint":"tcp://*:5556", "enable_kv_cache_events":true}' &

HABANA_VISIBLE_DEVICES=1 python3 -m dynamo.vllm \
    --model $MODEL \
    --block-size $BLOCK_SIZE \
    --connector none \
    --kv-events-config '{"publisher":"zmq","topic":"kv-events","endpoint":"tcp://*:5557", "enable_kv_cache_events":true}' &

HABANA_VISIBLE_DEVICES=2 python3 -m dynamo.vllm \
    --model $MODEL \
    --block-size $BLOCK_SIZE \
    --connector none \
    --kv-events-config '{"publisher":"zmq","topic":"kv-events","endpoint":"tcp://*:5562", "enable_kv_cache_events":true}' &

HABANA_VISIBLE_DEVICES=3 python3 -m dynamo.vllm \
    --model $MODEL \
    --block-size $BLOCK_SIZE \
    --connector none \
    --kv-events-config '{"publisher":"zmq","topic":"kv-events","endpoint":"tcp://*:5563", "enable_kv_cache_events":true}' &

HABANA_VISIBLE_DEVICES=4 python3 -m dynamo.vllm \
    --model $MODEL \
    --block-size $BLOCK_SIZE \
    --connector none \
    --kv-events-config '{"publisher":"zmq","topic":"kv-events","endpoint":"tcp://*:5558", "enable_kv_cache_events":true}' &

HABANA_VISIBLE_DEVICES=5 python3 -m dynamo.vllm \
    --model $MODEL \
    --block-size $BLOCK_SIZE \
    --connector none \
    --kv-events-config '{"publisher":"zmq","topic":"kv-events","endpoint":"tcp://*:5559", "enable_kv_cache_events":true}' &

HABANA_VISIBLE_DEVICES=6 python3 -m dynamo.vllm \
    --model $MODEL \
    --block-size $BLOCK_SIZE \
    --connector none \
    --kv-events-config '{"publisher":"zmq","topic":"kv-events","endpoint":"tcp://*:5560", "enable_kv_cache_events":true}' &

HABANA_VISIBLE_DEVICES=7 python3 -m dynamo.vllm \
    --model $MODEL \
    --block-size $BLOCK_SIZE \
    --connector none \
    --kv-events-config '{"publisher":"zmq","topic":"kv-events","endpoint":"tcp://*:5561", "enable_kv_cache_events":true}'
