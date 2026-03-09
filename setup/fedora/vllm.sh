uv venv --python 3.12 --seed --managed-python
source .venv/bin/activate
uv sync
uv pip install vllm --torch-backend=auto

touch launch.sh
chmod 700 launch.sh
echo "vllm serve Qwen/Qwen2.5-Coder-7B-Instruct-AWQ --dtype half --max-model-len 4096    --gpu-memory-utilization 0.93    --enforce-eager --port=18993" > launch.sh

