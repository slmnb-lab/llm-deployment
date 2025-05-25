#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR" || exit

# 配置GPU
if [[ "${USE_CUDA_DOCKER,,}" == "true" ]]; then
    echo "CUDA is enabled, configuring GPU environment"
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib/python3.11/site-packages/torch/lib:/usr/local/lib/python3.11/site-packages/nvidia/cudnn/lib"
    # 获取所有可用的GPU
    export CUDA_VISIBLE_DEVICES=$(nvidia-smi --query-gpu=index --format=csv,noheader | tr '\n' ',' | sed 's/,$//')
    echo "Using GPUs: $CUDA_VISIBLE_DEVICES"
fi

# 启动ollama服务
ollama serve &

# 等待ollama服务启动
until curl -s http://localhost:11434 > /dev/null; do 
    echo 'Waiting for Ollama service to start...'; 
    sleep 1; 
done

# 等待ollama服务启动完成
sleep 15

# 设置默认模型
DEFAULT_MODEL=${DEFAULT_MODEL:-qwen3:30b-a3b}

if ! ollama list | grep -q "$DEFAULT_MODEL"; then
    echo "Pulling default model: $DEFAULT_MODEL"
    ollama pull $DEFAULT_MODEL
fi

# Add conditional Playwright browser installation
if [[ "${WEB_LOADER_ENGINE,,}" == "playwright" ]]; then
    if [[ -z "${PLAYWRIGHT_WS_URL}" ]]; then
        echo "Installing Playwright browsers..."
        playwright install chromium
        playwright install-deps chromium
    fi

    python -c "import nltk; nltk.download('punkt_tab')"
fi

KEY_FILE=.webui_secret_key

PORT="${PORT:-8080}"
HOST="${HOST:-0.0.0.0}"
if test "$WEBUI_SECRET_KEY $WEBUI_JWT_SECRET_KEY" = " "; then
    echo "Loading WEBUI_SECRET_KEY from file, not provided as an environment variable."

    if ! [ -e "$KEY_FILE" ]; then
        echo "Generating WEBUI_SECRET_KEY"
        echo $(head -c 12 /dev/random | base64) > "$KEY_FILE"
    fi

    echo "Loading WEBUI_SECRET_KEY from $KEY_FILE"
    WEBUI_SECRET_KEY=$(cat "$KEY_FILE")
fi

if [[ "${USE_CUDA_DOCKER,,}" == "true" ]]; then
    echo "CUDA is enabled, appending LD_LIBRARY_PATH to include torch/cudnn & cublas libraries."
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib/python3.11/site-packages/torch/lib:/usr/local/lib/python3.11/site-packages/nvidia/cudnn/lib"
fi

# Check if SPACE_ID is set, if so, configure for space
if [ -n "$SPACE_ID" ]; then
    echo "Configuring for HuggingFace Space deployment"
    if [ -n "$ADMIN_USER_EMAIL" ] && [ -n "$ADMIN_USER_PASSWORD" ]; then
        echo "Admin user configured, creating"
        WEBUI_SECRET_KEY="$WEBUI_SECRET_KEY" uvicorn open_webui.main:app --host "$HOST" --port "$PORT" --forwarded-allow-ips '*' &
        webui_pid=$!
        echo "Waiting for webui to start..."
        while ! curl -s http://localhost:8080/health > /dev/null; do
            sleep 1
        done
        echo "Creating admin user..."
        curl \
            -X POST "http://localhost:8080/api/v1/auths/signup" \
            -H "accept: application/json" \
            -H "Content-Type: application/json" \
            -d "{ \"email\": \"${ADMIN_USER_EMAIL}\", \"password\": \"${ADMIN_USER_PASSWORD}\", \"name\": \"Admin\" }"
        echo "Shutting down webui..."
        kill $webui_pid
    fi

    export WEBUI_URL=${SPACE_HOST}
fi

PYTHON_CMD=$(command -v python3 || command -v python)

# 启动openwebui服务
WEBUI_SECRET_KEY="$WEBUI_SECRET_KEY" exec "$PYTHON_CMD" -m uvicorn open_webui.main:app --host "$HOST" --port "$PORT" --forwarded-allow-ips '*' --workers "${UVICORN_WORKERS:-1}"