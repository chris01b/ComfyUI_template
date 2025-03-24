#!/bin/bash
# Wan 2.1 Model Downloader for ComfyUI
# Uses high-speed HuggingFace transfer for optimal download performance

# Create all required directories
mkdir -p /ComfyUI/models/{text_encoders,vae,diffusion_models,clip_vision}

echo "Starting Wan 2.1 models download using optimized hf_transfer method..."

# Function to download a model if it doesn't exist
# Usage: download_model <model_type> <file_name>
download_model() {
    local model_type=$1
    local file_name=$2
    local dest_path="/ComfyUI/models/${model_type}/${file_name}"
    local source_path="split_files/${model_type}/${file_name}"
    local temp_dir="/ComfyUI/models/temp_download"
    
    if [ -f "$dest_path" ]; then
        echo "✓ ${file_name} already exists in ${model_type}"
    else
        echo "↓ Downloading ${file_name} to ${model_type}..."
        mkdir -p "$temp_dir"
        
        # Download to temporary directory
        huggingface-cli download Comfy-Org/Wan_2.1_ComfyUI_repackaged "$source_path" --local-dir "$temp_dir"
        
        # Check if file was downloaded (might be directly in temp_dir)
        if [ -f "$temp_dir/$file_name" ]; then
            # File was downloaded directly to temp_dir
            mkdir -p "/ComfyUI/models/${model_type}"
            mv "$temp_dir/$file_name" "$dest_path"
            echo "✓ Downloaded $file_name successfully"
        else
            # Check if downloaded with structure
            if [ -f "$temp_dir/$source_path" ]; then
                mkdir -p "/ComfyUI/models/${model_type}"
                mv "$temp_dir/$source_path" "$dest_path"
                echo "✓ Downloaded $file_name successfully"
            else
                echo "✗ Failed to download $file_name - file not found"
            fi
        fi
    fi
}

# Download all required model files
download_model "text_encoders" "umt5_xxl_fp8_e4m3fn_scaled.safetensors"
download_model "vae" "wan_2.1_vae.safetensors"
download_model "diffusion_models" "wan2.1_i2v_720p_14B_bf16.safetensors"
download_model "clip_vision" "clip_vision_h.safetensors"

# Install SageAttention
echo "Installing SageAttention..."
cd /

# Only clone if repo doesn't exist yet
if [ ! -d "/SageAttention" ]; then
    echo "Cloning SageAttention repository..."
    git clone https://github.com/thu-ml/SageAttention.git
fi

# Always install/update the package
cd /SageAttention
pip3 install -e .

# Clean up temporary download directories
rm -rf /ComfyUI/models/split_files
rm -rf /ComfyUI/models/temp_download

echo "✓ Wan 2.1 models installation completed successfully"
