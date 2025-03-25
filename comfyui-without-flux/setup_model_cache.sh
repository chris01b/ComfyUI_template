#!/bin/bash

# This script sets up a model cache directory for faster model loading
# It should be sourced before starting ComfyUI

# Default cache location
CACHE_DIR="/workspace/model_cache"

setup_model_cache() {
    echo "🔄 Setting up model cache for improved performance..."
    
    # Create cache directory if it doesn't exist
    mkdir -p $CACHE_DIR
    
    # Set environment variables for PyTorch and Hugging Face
    export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
    export CUDA_MODULE_LOADING=LAZY
    export TRANSFORMERS_CACHE=$CACHE_DIR
    export HF_HOME=$CACHE_DIR
    export HF_DATASETS_CACHE=$CACHE_DIR
    
    # For ComfyUI-specific optimizations
    export COMFYUI_TEMP_DIRECTORY=$CACHE_DIR/comfyui_temp
    mkdir -p $COMFYUI_TEMP_DIRECTORY
    
    # Performance optimization for CUDA drivers
    export CUDA_VISIBLE_DEVICES=0
    
    # Create an extra model paths config if it doesn't exist
    if [ ! -f "/workspace/extra_model_paths.yaml" ]; then
        echo "Creating extra model paths config..."
        cat > /workspace/extra_model_paths.yaml << EOL
# This file configures additional paths for models
paths:
  # Input
  input: /workspace/ComfyUI/input
  temp: $CACHE_DIR/comfyui_temp
  # Checkpoints / Models
  checkpoints: /workspace/ComfyUI/models/checkpoints
  configs: /workspace/ComfyUI/models/configs
  vae: /workspace/ComfyUI/models/vae
  loras: /workspace/ComfyUI/models/loras
  # Control networks / LoRAs
  controlnet: /workspace/ComfyUI/models/controlnet
  clip: /workspace/ComfyUI/models/clip
  clip_vision: /workspace/ComfyUI/models/clip_vision
  style_models: /workspace/ComfyUI/models/style_models
  embeddings: /workspace/ComfyUI/models/embeddings
  diffusers: /workspace/ComfyUI/models/diffusers
  vae_approx: /workspace/ComfyUI/models/vae_approx
  # Upscale models
  upscale_models: /workspace/ComfyUI/models/upscale_models
  # Custom directories
  custom_nodes: /workspace/ComfyUI/custom_nodes
EOL
    fi
    
    echo "✅ Model cache setup complete"
}

# Run the setup function
setup_model_cache 