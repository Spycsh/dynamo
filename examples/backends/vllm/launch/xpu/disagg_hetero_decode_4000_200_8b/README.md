```
aiconfigurator cli default --model-path Qwen/Qwen3-8B --backend vllm --backend-version 0.26.0 --total-gpus 4 --system b60 --isl 4000 --osl 200 --ttft 5000 --tpot 50 --enable-chunked-prefill
bs=22
2tp1+1tp2
4000 200
2.07 req/s
103.50tokens/s/gpu
22.43 tokens/s/user
```

```
baseline: xpu p+ xpu d
ours: xpu p+ xpu d + (1~2)*cpu d

future: xpu p+ xpu d + (1~2)*cpu d + device aware routing
```

# smoke

```
time curl -X POST "http://localhost:8000/v1/chat/completions"   -H "Content-Type: application/json"   -d '{
    "model": "/date/hf_models/Qwen3-8B/",
    "messages": [
      {
        "role": "user",
        "content": "Hello, how are you?"
      }
    ],
    "max_tokens": 50, "stream": false
  }'
```

xpu	1.9s
cpu	4.2s


# aiperf
```bash
bash perf.sh
```