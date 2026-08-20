#!/usr/bin/env bash
set -euo pipefail

# pip install aiperf==0.10.0
# Make sure DP * BS requests round-robin to DP decode workers, so each worker
# has BS requests on average.


bs=${bs:-22}
dp=${dp:-${D_DP:-1}}
concurrency=${concurrency:-$((bs * dp))}
model_name=${model_name:-/date/hf_models/Qwen3-8B/}
url=${url:-http://localhost:8000}
isl=4000
osl=200

aiperf profile \
    --model "${model_name}" \
    --tokenizer "${model_name}" \
    --endpoint-type chat \
    --endpoint /v1/chat/completions \
    --url "${url}" \
    --synthetic-input-tokens-mean "${isl}" \
    --synthetic-input-tokens-stddev 0 \
    --output-tokens-mean "${osl}" \
    --output-tokens-stddev 0 \
    --extra-inputs max_tokens:${osl} \
    --use-server-token-count \
    --streaming \
    --request-rate inf \
    --request-count $((concurrency * 14)) \
    --warmup-request-count $((concurrency * 2)) \
    --num-dataset-entries $((concurrency * 16)) \
    --random-seed 100 \
    --artifact-dir "res_disagg_isl${isl}_osl${osl}_bs${bs}_dp${dp}_conc${concurrency}" \
    --profile-export-prefix profile_req_inf \
    --ui simple \
    --no-server-metrics \
    --concurrency "${concurrency}" \
    --prefill-concurrency 2
