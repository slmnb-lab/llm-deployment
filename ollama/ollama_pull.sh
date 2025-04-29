#!/bin/bash
ollama serve &
sleep 15
ollama pull qwen3:30b-a3b

