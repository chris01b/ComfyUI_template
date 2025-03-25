#!/bin/bash

# Download helper functions for ComfyUI model downloads
# This script provides centralized functionality for downloading models efficiently 
# using huggingface-cli with HF_HUB_ENABLE_HF_TRANSFER

# Enable HF Transfer for faster downloads
export HF_HUB_ENABLE_HF_TRANSFER=1
echo "🚀 Using HF Transfer for faster downloads"

# Set default timeout and retry options for wget (as fallback)
WGET_OPTS="--timeout=60 --tries=3 --quiet"

# Function to download a model using huggingface-cli (preferred method)
download_hf() {
    local repo=$1
    local file_path=$2
    local dest_path=$3
    local use_auth=${4:-false}
    
    # Check if file already exists
    if [ -f "$dest_path" ]; then
        echo "✓ $(basename $dest_path) already exists, skipping download."
        return 0
    fi
    
    # Create destination directory if needed
    mkdir -p "$(dirname "$dest_path")"
    
    # Create a temporary directory for download
    local temp_dir=$(mktemp -d)
    
    echo "⬇️ Downloading $(basename $dest_path) from $repo using huggingface-cli with hf_transfer..."
    
    # Add token if authentication is needed
    local token_arg=""
    if [[ "$use_auth" == "true" ]] && [[ ! -z "${HF_TOKEN}" ]] && [[ "${HF_TOKEN}" != "enter_your_huggingface_token_here" ]]; then
        token_arg="--token ${HF_TOKEN}"
    fi
    
    # Download using huggingface-cli
    huggingface-cli download $token_arg $repo "$file_path" --local-dir "$temp_dir"
    local hf_result=$?
    
    # Handle the downloaded file
    if [ $hf_result -eq 0 ]; then
        # Try to find the file, checking both with full path or just the file name
        local file_name=$(basename "$file_path")
        
        if [ -f "$temp_dir/$file_path" ]; then
            mv "$temp_dir/$file_path" "$dest_path"
            echo "✓ Downloaded $(basename $dest_path) successfully"
            rm -rf "$temp_dir"
            return 0
        elif [ -f "$temp_dir/$file_name" ]; then
            mv "$temp_dir/$file_name" "$dest_path"
            echo "✓ Downloaded $(basename $dest_path) successfully"
            rm -rf "$temp_dir"
            return 0
        else
            echo "⚠️ HF download succeeded but file not found in expected location"
            ls -la "$temp_dir"  # Debug info
            rm -rf "$temp_dir"
            return 1
        fi
    else
        echo "⚠️ HF download failed, falling back to wget..."
        rm -rf "$temp_dir"
        return 1
    fi
}

# Function to download a model using wget (fallback method)
download_wget() {
    local url=$1
    local dest_path=$2
    local use_auth=${3:-false}
    
    # Check if file already exists
    if [ -f "$dest_path" ]; then
        echo "✓ $(basename $dest_path) already exists, skipping download."
        return 0
    fi
    
    # Create destination directory if needed
    mkdir -p "$(dirname "$dest_path")"
    
    echo "⬇️ Downloading $(basename $dest_path) using wget..."
    
    # Add token if authentication is needed
    local header_arg=""
    if [[ "$use_auth" == "true" ]] && [[ ! -z "${HF_TOKEN}" ]] && [[ "${HF_TOKEN}" != "enter_your_huggingface_token_here" ]]; then
        header_arg="--header=Authorization: Bearer ${HF_TOKEN}"
    fi
    
    # Download using wget
    wget $WGET_OPTS $header_arg -O "${dest_path}.tmp" "$url" && \
    mv "${dest_path}.tmp" "$dest_path" && \
    echo "✓ Downloaded $(basename $dest_path) successfully" || \
    { echo "❌ Failed to download $(basename $dest_path)"; rm -f "${dest_path}.tmp"; return 1; }
}

# Function to download a model with fallback
download_model() {
    local repo=$1
    local file_path=$2
    local dest_path=$3
    local url=$4
    local use_auth=${5:-false}
    
    # Try huggingface-cli first with HF_HUB_ENABLE_HF_TRANSFER, fallback to wget
    download_hf "$repo" "$file_path" "$dest_path" "$use_auth" || download_wget "$url" "$dest_path" "$use_auth"
}

# Function to download multiple models in parallel with controlled concurrency
download_models_parallel() {
    local max_concurrent=${1:-4}
    shift
    
    echo "⬇️ Starting parallel downloads with max $max_concurrent concurrent downloads..."
    
    # Run downloads in subshell to contain jobs
    (
        # Process each model info argument
        for model_info in "$@"; do
            # Wait for a slot before starting new download
            while [ $(jobs -r | wc -l) -ge $max_concurrent ]; do
                sleep 0.5
            done
            
            # Split the model info by : delimiter
            IFS=':' read -r repo file_path dest_path url use_auth <<< "$model_info"
            
            echo "Queueing download for $(basename "$dest_path")..."
            download_model "$repo" "$file_path" "$dest_path" "$url" "$use_auth" &
        done
        
        # Wait for all background jobs to finish
        wait
    )
    
    echo "✅ All downloads completed"
}

# Usage examples:
# 
# 1. Single download with fallback:
#    download_model "repo_name" "file_path" "/path/to/dest" "fallback_url" "true_if_auth_needed"
#
# 2. Multiple parallel downloads:
#    download_models_parallel 4 \
#      "repo1:file_path1:/dest_path1:fallback_url1:false" \
#      "repo2:file_path2:/dest_path2:fallback_url2:true" 