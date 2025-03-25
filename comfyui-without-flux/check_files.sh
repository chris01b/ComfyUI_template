#!/bin/bash

# This script checks if all required files and repositories are properly installed

echo "🔍 Checking for required model files..."

# FLUX model files check
if [[ ! -e "/workspace/ComfyUI/models/vae/ae.sft" ]]; then
    echo "⚠️ FLUX VAE model (ae.sft) not found, model will not work properly."
    echo "   Please set HF_TOKEN environment variable and restart pod with DOWNLOAD_FLUX=true"
    MISSING_FILES=1
else
    echo "✅ FLUX VAE model (ae.sft) found"
fi

if [[ ! -e "/workspace/ComfyUI/models/diffusion_models/flux1-dev.sft" ]]; then
    echo "⚠️ FLUX diffusion model (flux1-dev.sft) not found, model will not work properly."
    echo "   Please set HF_TOKEN environment variable and restart pod with DOWNLOAD_FLUX=true"
    MISSING_FILES=1
else
    echo "✅ FLUX diffusion model (flux1-dev.sft) found"
fi

# Text encoder checks
if [[ ! -e "/workspace/ComfyUI/models/clip/clip_l.safetensors" ]]; then
    echo "⚠️ CLIP-L model not found"
    MISSING_FILES=1
else
    echo "✅ CLIP-L model found"
fi

if [[ ! -e "/workspace/ComfyUI/models/clip/t5xxl_fp8_e4m3fn.safetensors" ]]; then
    echo "⚠️ T5 model not found"
    MISSING_FILES=1
else
    echo "✅ T5 model found"
fi

# Check for required repositories
echo "🔍 Checking for required repositories..."

# Function to check if a repository exists and is properly installed
check_repo() {
    local repo_path=$1
    local repo_name=$2
    
    if [[ -d "$repo_path" ]]; then
        echo "✅ $repo_name repository found"
        return 0
    else
        echo "⚠️ $repo_name repository not found or not properly installed"
        return 1
    fi
}

# Check core repositories
check_repo "/workspace/ComfyUI" "ComfyUI"
check_repo "/workspace/ComfyUI/custom_nodes/ComfyUI-Manager" "ComfyUI-Manager"
check_repo "/workspace/ComfyUI/custom_nodes/ComfyUI-Impact-Pack" "ComfyUI-Impact-Pack"

# Check if any important repositories are missing
if [[ -f "/installed_repos.txt" ]]; then
    REPO_COUNT=$(cat /installed_repos.txt | wc -l)
    echo "ℹ️ $REPO_COUNT repositories successfully installed"
else
    echo "⚠️ Repository installation tracking file not found"
fi

# Summary output
if [[ $MISSING_FILES -eq 1 ]]; then
    echo "⚠️ Some required files are missing. ComfyUI might not work properly."
    echo "   You may need to download missing models or install missing repositories."
else
    echo "✅ All required files checked successfully"
fi
