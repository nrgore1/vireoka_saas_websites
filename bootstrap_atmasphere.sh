#!/usr/bin/env bash
set -e

echo "=============================================="
echo "🌌 AtmaSphereLLM — Full Project Bootstrap"
echo "=============================================="
echo ""

#####################################
# Helper: Ensure command exists
#####################################
require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "❌ ERROR: '$1' is not installed or not in PATH."
    exit 1
  else
    echo "✔ Found: $1"
  fi
}

echo "🔍 Checking system dependencies..."
require_cmd python3
require_cmd pip
require_cmd docker
require_cmd docker-compose
require_cmd helm
require_cmd kubectl

echo ""
echo "📁 Ensuring directory structure..."

mkdir -p research_hub/ingestion
mkdir -p rag_faiss
mkdir -p qwen3_training/scripts
mkdir -p qwen3_training/config
mkdir -p qwen3_training/data
mkdir -p tokenizer_ext/vocab
mkdir -p alignment_server
mkdir -p council_engine
mkdir -p gateway
mkdir -p helm/atmasphere-llm/templates
mkdir -p k8s
mkdir -p data

echo "✔ Directories created."

#####################################
# Restore Batches 1–9 if missing
#####################################

restore_if_missing() {
  local file="$1"
  local batch_file="$2"
  
  if [ ! -f "$file" ]; then
    echo "📝 Restoring missing file: $file"
    cp "$batch_file" "$file"
  fi
}

echo "🔍 Checking all required files from batches..."

# Batch 1–2
restore_if_missing research_hub/ingestion/schemas.py research_hub/ingestion/schemas.py
restore_if_missing research_hub/ingestion/loaders.py research_hub/ingestion/loaders.py
restore_if_missing research_hub/ingestion/service.py research_hub/ingestion/service.py

# Batch 3 – Qwen training scripts
restore_if_missing qwen3_training/scripts/train_sft_ms_swift.py qwen3_training/scripts/train_sft_ms_swift.py
restore_if_missing qwen3_training/scripts/train_dpo_ms_swift.py qwen3_training/scripts/train_dpo_ms_swift.py
restore_if_missing qwen3_training/scripts/train_rm_ms_swift.py qwen3_training/scripts/train_rm_ms_swift.py
restore_if_missing qwen3_training/config/qwen3_sft_ms_swift.yaml qwen3_training/config/qwen3_sft_ms_swift.yaml
restore_if_missing qwen3_training/config/qwen3_dpo_ms_swift.yaml qwen3_training/config/qwen3_dpo_ms_swift.yaml
restore_if_missing qwen3_training/config/qwen3_rm_ms_swift.yaml qwen3_training/config/qwen3_rm_ms_swift.yaml

# Batch 4 – RAG system
restore_if_missing rag_faiss/rag_config.py rag_faiss/rag_config.py
restore_if_missing rag_faiss/encoder.py rag_faiss/encoder.py
restore_if_missing rag_faiss/store.py rag_faiss/store.py
restore_if_missing rag_faiss/indexer.py rag_faiss/indexer.py
restore_if_missing rag_faiss/service.py rag_faiss/service.py

# Batch 5 – Alignment server
restore_if_missing alignment_server/jvb_value_profiles.py alignment_server/jvb_value_profiles.py
restore_if_missing alignment_server/schemas.py alignment_server/schemas.py
restore_if_missing alignment_server/filters.py alignment_server/filters.py
restore_if_missing alignment_server/router.py alignment_server/router.py
restore_if_missing alignment_server/main.py alignment_server/main.py
restore_if_missing alignment_server/Dockerfile alignment_server/Dockerfile

# Batch 6 – Council engine
restore_if_missing council_engine/roles.py council_engine/roles.py
restore_if_missing council_engine/orchestrator.py council_engine/orchestrator.py
restore_if_missing council_engine/server.py council_engine/server.py
restore_if_missing council_engine/Dockerfile council_engine/Dockerfile

# Batch 7 – Gateway
restore_if_missing gateway/config.py gateway/config.py
restore_if_missing gateway/models.py gateway/models.py
restore_if_missing gateway/qwen_infer.py gateway/qwen_infer.py
restore_if_missing gateway/clients.py gateway/clients.py
restore_if_missing gateway/app.py gateway/app.py
restore_if_missing gateway/Dockerfile gateway/Dockerfile

# Batch 8 – K8s + Helm + docker-compose
restore_if_missing docker-compose.dev.yml docker-compose.dev.yml

#####################################
# Install Python dependencies
#####################################
echo ""
echo "📦 Installing Python dependencies (system-wide virtualenv recommended)..."

pip install --upgrade pip
pip install fastapi uvicorn[standard] openai \
           transformers torch accelerate sentencepiece \
           pydantic httpx python-multipart \
           ms-swift datasets faiss-cpu

echo "✔ Python dependencies installed."

#####################################
# Final messages
#####################################
echo ""
echo "=============================================="
echo "🚀 AtmaSphereLLM bootstrap complete!"
echo "=============================================="
echo ""
echo "Next steps:"
echo "- Run the local stack:        docker compose -f docker-compose.dev.yml up --build"
echo "- Ingest documents:           curl -F \"file=@doc.pdf\" localhost:8001/ingest"
echo "- Chat with gateway:          curl -X POST localhost:8080/chat -d '{\"query\": \"Hello\"}'"
echo "- Deploy to Kubernetes:       helm install atma helm/atmasphere-llm -n atmasphere-llm"
echo ""
echo "✨ You are ready to use AtmaSphereLLM!"
