#!/usr/bin/env bash
set -euo pipefail

# Bailian agent-trace replay smoke/full benchmark for the local Dynamo endpoint.
#
# Typical use:
#   source /root/sihan/llm-d/.venv/bin/activate
#   cd /root/sihan/aiperf
#   WINDOW_MS=20000 POLICY=baseline bash /root/sihan/dynamo/examples/backends/vllm/launch/xpu/disagg_hetero_decode_4000_200_8b/agent_perf.sh
#
# Notes:
# - MODEL_NAME is the model id sent to the server. For the local Dynamo/vLLM stack
#   it can be the served local path, for example /date/hf_models/Qwen3-8B/.
# - TOKENIZER_NAME is for AIPerf-side trace decoding. Prefer the HF repo id
#   Qwen/Qwen3-8B instead of the local path, because Bailian trace decoding uses
#   parallel worker processes and expects the tokenizer snapshot in HF cache.
# - If tokenizer loading fails with HFValidationError or missing files, refresh the
#   cache once with network/proxy enabled, then rerun this script.
# - Use the first run after restarting decode workers for fair cache-sensitive
#   policy comparisons. Later repeats may reuse KV cache populated by earlier runs.


ENDPOINT_URL=${ENDPOINT_URL:-http://127.0.0.1:8000}
MODEL_NAME=${MODEL_NAME:-/date/hf_models/Qwen3-8B/}
TOKENIZER_NAME=${TOKENIZER_NAME:-Qwen/Qwen3-8B}
TRACE=${TRACE:-/root/sihan/qwen-bailian-usagetraces-anon/qwen_traceA_blksz_16.jsonl}
TRACE_NAME=${TRACE_NAME:-$(basename "${TRACE}" .jsonl)}
WINDOW_MS=${WINDOW_MS:-60000}
POLICY=${POLICY:-baseline}
RESULT_ROOT=${RESULT_ROOT:-/root/sihan/results}
ARTIFACT_DIR=${ARTIFACT_DIR:-${RESULT_ROOT}/aiperf-${POLICY}-${TRACE_NAME}-${WINDOW_MS}ms}
LOG_FILE=${LOG_FILE:-${ARTIFACT_DIR}.log}

mkdir -p "${RESULT_ROOT}"

cat <<EOF
Agent trace replay configuration:
  endpoint:     ${ENDPOINT_URL}
  model:        ${MODEL_NAME}
  tokenizer:    ${TOKENIZER_NAME}
  trace:        ${TRACE}
  window_ms:    ${WINDOW_MS}
  policy:       ${POLICY}
  artifact_dir: ${ARTIFACT_DIR}
  log_file:     ${LOG_FILE}
EOF

aiperf profile \
  --model "${MODEL_NAME}" \
  --tokenizer "${TOKENIZER_NAME}" \
  --url "${ENDPOINT_URL}" \
  --endpoint-type chat \
  --streaming \
  --input-file "${TRACE}" \
  --custom-dataset-type bailian_trace \
  --fixed-schedule \
  --fixed-schedule-auto-offset \
  --fixed-schedule-end-offset "${WINDOW_MS}" \
  --output-artifact-dir "${ARTIFACT_DIR}" \
  2>&1 | tee "${LOG_FILE}"
