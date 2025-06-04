#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR" || exit

echo 'begin to start ollama...'; 
# 启动ollama服务
ollama serve &

# 等待ollama服务启动
until curl -s http://localhost:11434 > /dev/null; do 
    echo 'Waiting for Ollama service to start...'; 
    sleep 1; 
done

# 等待ollama服务启动完成
sleep 15

DEFAULT_MODEL=${DEFAULT_MODEL:-qwen3:30b-a3b}

if ! ollama list | grep -q "$DEFAULT_MODEL"; then
    echo "Pulling default model: $DEFAULT_MODEL"
    ollama pull $DEFAULT_MODEL
fi

echo 'begin to start open webui...'; 

# 启动Web UI
./start.sh 


