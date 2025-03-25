#!/bin/bash

# Source the download helper functions
source /download_helper.sh

# Function to download FLUX models (with authentication)
download_flux_models() {
    if [[ -z "${HF_TOKEN}" ]] || [[ "${HF_TOKEN}" == "enter_your_huggingface_token_here" ]]; then
        echo "⚠️ HF_TOKEN is not set, can not download flux because it is a gated repository."
        return 1
    fi
    
    echo "🔑 HF_TOKEN is set, downloading FLUX models..."
    
    # Create required directories
    mkdir -p "/ComfyUI/models/vae" "/ComfyUI/models/diffusion_models"
    
    # Download FLUX models using the helper
    download_models_parallel 2 \
        "black-forest-labs/FLUX.1-dev:ae.safetensors:/ComfyUI/models/vae/ae.sft:https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/ae.safetensors?download=true:true" \
        "black-forest-labs/FLUX.1-dev:flux1-dev.safetensors:/ComfyUI/models/diffusion_models/flux1-dev.sft:https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/flux1-dev.safetensors?download=true:true"
}

# Download public models
download_public_models() {
    # Create all required directories first
    mkdir -p "/ComfyUI/models/clip" "/ComfyUI/models/loras" "/ComfyUI/models/xlabs/loras"
    
    echo "⬇️ Starting downloads of required models..."
    
    # Download all public models using the helper
    download_models_parallel 5 \
        "comfyanonymous/flux_text_encoders:clip_l.safetensors:/ComfyUI/models/clip/clip_l.safetensors:https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors?download=true:false" \
        "comfyanonymous/flux_text_encoders:t5xxl_fp8_e4m3fn.safetensors:/ComfyUI/models/clip/t5xxl_fp8_e4m3fn.safetensors:https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp8_e4m3fn.safetensors?download=true:false" \
        "WouterGlorieux/GracePenelopeTargaryenV5:GracePenelopeTargaryenV5.safetensors:/ComfyUI/models/loras/GracePenelopeTargaryenV5.safetensors:https://huggingface.co/WouterGlorieux/GracePenelopeTargaryenV5/resolve/main/GracePenelopeTargaryenV5.safetensors?download=true:false" \
        "VideoAditor/Flux-Lora-Realism:flux_realism_lora.safetensors:/ComfyUI/models/loras/VideoAditor_flux_realism_lora.safetensors:https://huggingface.co/VideoAditor/Flux-Lora-Realism/resolve/main/flux_realism_lora.safetensors?download=true:false" \
        "XLabs-AI/flux-RealismLora:lora.safetensors:/ComfyUI/models/xlabs/loras/Xlabs-AI_flux-RealismLora.safetensors:https://huggingface.co/XLabs-AI/flux-RealismLora/resolve/main/lora.safetensors?download=true:false"
}

# First handle FLUX models with authentication
download_flux_models

# Download public models
download_public_models

echo "✓ All model downloads complete"
