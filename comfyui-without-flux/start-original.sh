#!/bin/bash

# You can make modifications to this file if you want to customize the startup process.
# Things like installing additional custom nodes, or downloading models can be done here.

# Verify repository installations
echo "🔍 Verifying repository installations..."
if [[ -f "/installed_repos.txt" ]]; then
    REPO_COUNT=$(cat /installed_repos.txt | wc -l)
    echo "✅ $REPO_COUNT repositories verified"
else
    echo "⚠️ Repository tracking file not found, installations may be incomplete"
fi

# Source the model cache setup script
if [ -f "/setup_model_cache.sh" ]; then
    echo "🚀 Setting up model cache for improved performance..."
    source /setup_model_cache.sh
fi

# Update the included workflows
echo "✨ Updating workflows..."
bash /update_Workflows.sh &
WORKFLOW_PID=$!

# Disable Mixlab nodes because they take a long time load and are no longer needed in any of the included workflows.
# But can be enabled if needed by commenting out the following line.
echo "🔧 Disabling Mixlab nodes to improve startup time..."
bash /disable_mixlab.sh &
MIXLAB_PID=$!

# Wait for background tasks to complete
wait $WORKFLOW_PID $MIXLAB_PID

# Set performance optimization flags
export CUDA_MODULE_LOADING=LAZY
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512

# Launch the UI with optimized settings
echo "🚀 Launching ComfyUI interface..."
python3 /workspace/ComfyUI/main.py --listen --port 8188 --extra-model-paths-config /workspace/extra_model_paths.yaml

# Keep the container running indefinitely
echo "🔄 ComfyUI process exited, keeping container alive..."
sleep infinity
