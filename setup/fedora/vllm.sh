uv venv --python 3.12 --seed --managed-python
source .venv/bin/activate
uv sync
uv pip install vllm --torch-backend=auto

rm -f launch.sh 
touch launch.sh
chmod 700 launch.sh

(
  echo "export VLLM_ALLOW_LONG_MAX_MODEL_LEN=1"
  echo "vllm serve Qwen/Qwen2.5-Coder-7B-Instruct-AWQ \\"
  echo "  --dtype half \\"
  echo "  --max-model-len 16284 \\"
  echo "  --max-num-seqs 1 \\"
  echo "  --gpu-memory-utilization 0.93 \\"
  echo "  --enable-auto-tool-choice \\"
  echo "  --tool-call-parser qwen3_xml \\"
  echo "  --enforce-eager \\"
  echo "  --port 18993"
) > launch.sh


