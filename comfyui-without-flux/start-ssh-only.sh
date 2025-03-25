#!/bin/bash

echo "🚀 Starting ComfyUI pod setup..."

# Setup SSH if PUBLIC_KEY is provided
if [[ $PUBLIC_KEY ]]; then
    echo "🔐 Setting up SSH with provided public key..."
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    cd ~/.ssh
    echo $PUBLIC_KEY >> authorized_keys
    chmod 700 -R ~/.ssh
    cd /
    service ssh start &
    SSH_PID=$!
fi

# Login to HuggingFace if token is provided
if [[ -z "${HF_TOKEN}" ]] || [[ "${HF_TOKEN}" == "enter_your_huggingface_token_here" ]]; then
    echo "⚠️ HF_TOKEN is not set or is default value"
else
    echo "🔑 Logging in to HuggingFace..."
    huggingface-cli login --token ${HF_TOKEN}
fi

# Start services in parallel
# Start nginx as reverse proxy for API access
echo "🌐 Starting nginx..."
service nginx start &
NGINX_PID=$!

# Start JupyterLab
echo "📓 Starting JupyterLab..."
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.allow_origin='*' &
JUPYTER_PID=$!

# Run persistence setup scripts in parallel (these create symlinks for persistence)
echo "💾 Setting up persistent workspace..."
/comfyui-on-workspace.sh &
COMFY_SETUP_PID=$!

/ai-toolkit-on-workspace.sh &
AI_TOOLKIT_SETUP_PID=$!

# Wait for persistence setup to complete
wait $COMFY_SETUP_PID $AI_TOOLKIT_SETUP_PID
echo "✅ Workspace persistence setup complete"

# Check and download models in parallel if enabled
DOWNLOAD_TASKS=()

if [[ "${DOWNLOAD_WAN}" == "true" ]]; then
    echo "🔄 Starting WAN 2.1 download..."
    /download_wan2.1.sh &
    DOWNLOAD_TASKS+=($!)
fi

if [[ "${DOWNLOAD_FLUX}" == "true" ]]; then
    echo "🔄 Starting FLUX download..."
    /download_Files.sh &
    DOWNLOAD_TASKS+=($!)
fi

# Wait for all download tasks if any were started
if [ ${#DOWNLOAD_TASKS[@]} -gt 0 ]; then
    echo "⏳ Waiting for downloads to complete..."
    wait ${DOWNLOAD_TASKS[@]}
    echo "✅ Downloads complete"
fi

# Check if FLUX model files are present
echo "🔍 Checking required files..."
bash /check_files.sh

# Set up virtual environment if needed
if [ -d "/workspace/venv" ]; then
    echo "🐍 Virtual environment found, activating..."
    source /workspace/venv/bin/activate
fi

# Check and set up user's startup script
if [ ! -f /workspace/start_user.sh ]; then
    echo "📄 Creating user startup script..."
    cp /start-original.sh /workspace/start_user.sh
fi

# Execute the user's script
echo "🚀 Launching ComfyUI..."
bash /workspace/start_user.sh

# Keep the container running
sleep infinity
