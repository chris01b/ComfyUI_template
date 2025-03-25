#!/bin/bash

# Create required directories
mkdir -p /ComfyUI/models/{text_encoders,vae,diffusion_models,clip_vision}

# Source the download helper functions
source /download_helper.sh

echo "✨ Starting Wan2.1 installation process..."

# Install SageAttention in background
install_sageattention() {
    echo "🔧 Installing SageAttention..."
    
    # Use the helper script for consistent git cloning behavior
    /clone_repo.sh "https://github.com/thu-ml/SageAttention.git" "/SageAttention" "main"
    
    if [ $? -eq 0 ]; then
        cd /SageAttention
        pip3 install -e . > /dev/null 2>&1
        echo "✓ SageAttention installed successfully"
        echo "SageAttention" >> /installed_repos.txt
    else
        echo "❌ Failed to install SageAttention"
    fi
}

# Start SageAttention installation
install_sageattention &
SAGE_PID=$!

# Define models to download
echo "⬇️ Starting Wan2.1 parallel model downloads using hf_transfer..."

# Define all models to download
download_models_parallel 4 \
    "Comfy-Org/Wan_2.1_ComfyUI_repackaged:split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors:/ComfyUI/models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors:https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors?download=true:false" \
    "Comfy-Org/Wan_2.1_ComfyUI_repackaged:split_files/vae/wan_2.1_vae.safetensors:/ComfyUI/models/vae/wan_2.1_vae.safetensors:https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors?download=true:false" \
    "Comfy-Org/Wan_2.1_ComfyUI_repackaged:split_files/diffusion_models/wan2.1_i2v_720p_14B_bf16.safetensors:/ComfyUI/models/diffusion_models/wan2.1_i2v_720p_14B_bf16.safetensors:https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_i2v_720p_14B_bf16.safetensors?download=true:false" \
    "Comfy-Org/Wan_2.1_ComfyUI_repackaged:split_files/clip_vision/clip_vision_h.safetensors:/ComfyUI/models/clip_vision/clip_vision_h.safetensors:https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors?download=true:false"

# Wait for SageAttention installation
wait $SAGE_PID

# Clean up temporary download directories
rm -rf /ComfyUI/models/split_files
rm -rf /ComfyUI/models/temp_download

echo "✅ Wan2.1 installation completed successfully"
