ARG CUDA_VERSION="12.6.3"
ARG UBUNTU_VERSION="24.04"
ARG DOCKER_FROM=nvidia/cuda:$CUDA_VERSION-cudnn-devel-ubuntu$UBUNTU_VERSION
ARG HF_TOKEN=""

# Base NVidia CUDA Ubuntu image
FROM $DOCKER_FROM AS base

# Set environment variables
ENV PIP_BREAK_SYSTEM_PACKAGES=1
ENV PATH="/usr/local/cuda/bin:${PATH}"
ENV HF_HUB_ENABLE_HF_TRANSFER=1

# Install system dependencies in a single layer
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv python3-dev \
    openssh-server openssh-client \
    git git-lfs \
    wget vim zip unzip curl \
    nginx \
    libgl1 libglx-mesa0 libglib2.0-0 && \
    mkdir -p /usr/share/fonts/truetype && \
    # Copy the 'default' configuration file to the appropriate location
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Configure git for better clone performance
RUN git config --global http.lowSpeedLimit 1000 && \
    git config --global http.lowSpeedTime 60 && \
    git config --global http.postBuffer 524288000 && \
    git config --global core.compression 9 && \
    git config --global advice.detachedHead false

COPY default /etc/nginx/sites-available/default

# Install pytorch and HuggingFace Hub (change less frequently)
ARG PYTORCH="2.6.0"
ARG CUDA="126"
RUN pip3 install --no-cache-dir -U torch==$PYTORCH torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu$CUDA && \
    pip3 install -U "huggingface_hub[cli,hf_transfer]" && \
    pip3 install jupyterlab

# Copy all scripts at once (changes less frequently than code)
COPY --chmod=755 start-ssh-only.sh /start.sh
COPY --chmod=755 start-original.sh /start-original.sh
COPY --chmod=755 comfyui-on-workspace.sh /comfyui-on-workspace.sh
COPY --chmod=755 ai-toolkit-on-workspace.sh /ai-toolkit-on-workspace.sh
COPY --chmod=755 check_files.sh /check_files.sh
COPY --chmod=755 download_*.sh /
COPY --chmod=755 update_Workflows.sh /update_Workflows.sh
COPY --chmod=755 make_venv.sh /make_venv.sh
COPY --chmod=755 disable_mixlab.sh /disable_mixlab.sh
COPY --chmod=644 defaultGraph.json /defaultGraph.json
COPY --chmod=755 replaceDefaultGraph.py /replaceDefaultGraph.py

# Helper function for proper git cloning
COPY --chmod=755 clone_repo.sh /clone_repo.sh

# Helper function for improved downloads
COPY --chmod=755 download_helper.sh /download_helper.sh

# Clone ComfyUI and install core requirements
RUN /clone_repo.sh "https://github.com/comfyanonymous/ComfyUI.git" "/ComfyUI" "master" && \
    cd /ComfyUI && \
    pip3 install -r requirements.txt && \
    mkdir -p custom_nodes pysssss-workflows

# Create a file to track successful installations
RUN touch /installed_repos.txt

# Install core custom nodes (most commonly used/essential)
RUN cd /ComfyUI/custom_nodes && \
    /clone_repo.sh "https://github.com/ltdrdata/ComfyUI-Manager.git" "./ComfyUI-Manager" "main" && \
    /clone_repo.sh "https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git" "./ComfyUI-Custom-Scripts" "main" && \
    /clone_repo.sh "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git" "./ComfyUI-Impact-Pack" "Main" && \
    echo "ComfyUI-Manager" >> /installed_repos.txt && \
    echo "ComfyUI-Custom-Scripts" >> /installed_repos.txt && \
    cd ComfyUI-Impact-Pack && pip3 install -r requirements.txt && python3 install.py && echo "ComfyUI-Impact-Pack" >> /installed_repos.txt

# Install additional custom nodes in parallel groups
RUN cd /ComfyUI/custom_nodes && \
    # Group 1: Upscale nodes
    /clone_repo.sh "https://github.com/flowtyone/ComfyUI-Flowty-LDSR.git" "./ComfyUI-Flowty-LDSR" "master" && \
    /clone_repo.sh "https://github.com/kijai/ComfyUI-SUPIR.git" "./ComfyUI-SUPIR" "main" && \
    /clone_repo.sh "https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git" "./ComfyUI_UltimateSDUpscale" "main" "--recursive" && \
    # Install requirements for these nodes
    cd ComfyUI-Flowty-LDSR && pip3 install -r requirements.txt && echo "ComfyUI-Flowty-LDSR" >> /installed_repos.txt && cd .. && \
    cd ComfyUI-SUPIR && pip3 install -r requirements.txt && echo "ComfyUI-SUPIR" >> /installed_repos.txt && cd .. && \
    echo "ComfyUI_UltimateSDUpscale" >> /installed_repos.txt

# Install more custom nodes (second batch)
RUN cd /ComfyUI/custom_nodes && \
    # Group 2: Utility and UI nodes
    /clone_repo.sh "https://github.com/kijai/ComfyUI-KJNodes.git" "./ComfyUI-KJNodes" "main" && \
    /clone_repo.sh "https://github.com/rgthree/rgthree-comfy.git" "./rgthree-comfy" "main" && \
    /clone_repo.sh "https://github.com/JPS-GER/ComfyUI_JPS-Nodes.git" "./ComfyUI_JPS-Nodes" "main" && \
    /clone_repo.sh "https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git" "./ComfyUI_Comfyroll_CustomNodes" "main" && \
    /clone_repo.sh "https://github.com/Jordach/comfy-plasma.git" "./comfy-plasma" "main" && \
    /clone_repo.sh "https://github.com/theUpsider/ComfyUI-Logic.git" "./ComfyUI-Logic" "master" && \
    # Install requirements for these nodes
    cd ComfyUI-KJNodes && pip3 install -r requirements.txt && echo "ComfyUI-KJNodes" >> /installed_repos.txt && cd .. && \
    cd rgthree-comfy && pip3 install -r requirements.txt && echo "rgthree-comfy" >> /installed_repos.txt && cd .. && \
    echo "ComfyUI_JPS-Nodes" >> /installed_repos.txt && \
    echo "ComfyUI_Comfyroll_CustomNodes" >> /installed_repos.txt && \
    echo "comfy-plasma" >> /installed_repos.txt && \
    echo "ComfyUI-Logic" >> /installed_repos.txt

# Install more custom nodes (third batch)
RUN cd /ComfyUI/custom_nodes && \
    # Group 3: Video and image processing
    /clone_repo.sh "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git" "./ComfyUI-VideoHelperSuite" "main" && \
    /clone_repo.sh "https://github.com/PowerHouseMan/ComfyUI-AdvancedLivePortrait.git" "./ComfyUI-AdvancedLivePortrait" "main" && \
    /clone_repo.sh "https://github.com/ltdrdata/ComfyUI-Impact-Subpack" "./ComfyUI-Impact-Subpack" "main" && \
    /clone_repo.sh "https://github.com/Fannovel16/comfyui_controlnet_aux.git" "./comfyui_controlnet_aux" "main" && \
    # Install requirements
    cd ComfyUI-VideoHelperSuite && pip3 install -r requirements.txt && echo "ComfyUI-VideoHelperSuite" >> /installed_repos.txt && cd .. && \
    cd ComfyUI-AdvancedLivePortrait && pip3 install -r requirements.txt && echo "ComfyUI-AdvancedLivePortrait" >> /installed_repos.txt && cd .. && \
    cd ComfyUI-Impact-Subpack && pip3 install -r requirements.txt && echo "ComfyUI-Impact-Subpack" >> /installed_repos.txt && cd .. && \
    cd comfyui_controlnet_aux && pip3 install -r requirements.txt && echo "comfyui_controlnet_aux" >> /installed_repos.txt && cd ..

# Install final batch of custom nodes
RUN cd /ComfyUI/custom_nodes && \
    /clone_repo.sh "https://github.com/yolain/ComfyUI-Easy-Use.git" "./ComfyUI-Easy-Use" "main" && \
    /clone_repo.sh "https://github.com/kijai/ComfyUI-Florence2.git" "./ComfyUI-Florence2" "main" && \
    /clone_repo.sh "https://github.com/WASasquatch/was-node-suite-comfyui.git" "./was-node-suite-comfyui" "main" && \
    /clone_repo.sh "https://github.com/cubiq/ComfyUI_essentials.git" "./ComfyUI_essentials" "main" && \
    /clone_repo.sh "https://github.com/chrisgoringe/cg-image-picker.git" "./cg-image-picker" "main" && \
    /clone_repo.sh "https://github.com/chflame163/ComfyUI_LayerStyle.git" "./ComfyUI_LayerStyle" "main" && \
    /clone_repo.sh "https://github.com/shadowcz007/comfyui-mixlab-nodes.git" "./comfyui-mixlab-nodes" "main" && \
    /clone_repo.sh "https://github.com/chrisgoringe/cg-use-everywhere.git" "./cg-use-everywhere" "main" && \
    /clone_repo.sh "https://github.com/kijai/ComfyUI-CogVideoXWrapper.git" "./ComfyUI-CogVideoXWrapper" "main" && \
    /clone_repo.sh "https://codeberg.org/Gourieff/comfyui-reactor-node.git" "./comfyui-reactor-node" "main" && \
    # Install requirements
    cd ComfyUI-Easy-Use && pip3 install -r requirements.txt && echo "ComfyUI-Easy-Use" >> /installed_repos.txt && cd .. && \
    cd ComfyUI-Florence2 && pip3 install -r requirements.txt && mkdir -p /ComfyUI/models/LLM && echo "ComfyUI-Florence2" >> /installed_repos.txt && cd .. && \
    cd was-node-suite-comfyui && pip3 install -r requirements.txt && echo "was-node-suite-comfyui" >> /installed_repos.txt && cd .. && \
    cd ComfyUI_essentials && pip3 install -r requirements.txt && echo "ComfyUI_essentials" >> /installed_repos.txt && cd .. && \
    echo "cg-image-picker" >> /installed_repos.txt && \
    cd ComfyUI_LayerStyle && pip3 install -r requirements.txt && echo "ComfyUI_LayerStyle" >> /installed_repos.txt && cd .. && \
    cd comfyui-mixlab-nodes && pip3 install -r requirements.txt && echo "comfyui-mixlab-nodes" >> /installed_repos.txt && cd .. && \
    echo "cg-use-everywhere" >> /installed_repos.txt && \
    cd ComfyUI-CogVideoXWrapper && pip3 install -r requirements.txt && echo "ComfyUI-CogVideoXWrapper" >> /installed_repos.txt && cd .. && \
    cd comfyui-reactor-node && pip3 install -r requirements.txt && echo "comfyui-reactor-node" >> /installed_repos.txt && cd ..

# Set up directories and download key model files using download_helper.sh
RUN mkdir -p /ComfyUI/models/ultralytics/bbox && \
    mkdir -p /ComfyUI/models/insightface && \
    mkdir -p /ComfyUI/models/LLM && \
    mkdir -p /ComfyUI/models/checkpoints && \
    chmod +x /download_helper.sh && \
    if [ ! -z "${HF_TOKEN}" ] && [ "${HF_TOKEN}" != "enter_your_huggingface_token_here" ]; then \
        echo "🔑 Logging in to HuggingFace..." && \
        huggingface-cli login --token ${HF_TOKEN}; \
    fi && \
    bash -c '. /download_helper.sh && \
    download_models_parallel 3 \
      "Bingsu/adetailer:face_yolov8m.pt:/ComfyUI/models/ultralytics/bbox/face_yolov8m.pt:https://huggingface.co/Bingsu/adetailer/resolve/main/face_yolov8m.pt?download=true:true" \
      "ezioruan/inswapper_128.onnx:inswapper_128.onnx:/ComfyUI/models/insightface/inswapper_128.onnx:https://huggingface.co/ezioruan/inswapper_128.onnx/resolve/main/inswapper_128.onnx?download=true:true" \
      "Comfy-Org/stable-diffusion-v1-5-archive:v1-5-pruned-emaonly-fp16.safetensors:/ComfyUI/models/checkpoints/v1-5-pruned-emaonly-fp16.safetensors:https://huggingface.co/Comfy-Org/stable-diffusion-v1-5-archive/resolve/main/v1-5-pruned-emaonly-fp16.safetensors?download=true:true"' && \
    wget -q "https://raw.githubusercontent.com/comfyanonymous/ComfyUI_examples/master/flux/flux_dev_example.png" -P /ComfyUI

# Clone AI-Toolkit (in separate layer since it's quite large)
RUN /clone_repo.sh "https://github.com/ostris/ai-toolkit.git" "/ai-toolkit" "main" "--recurse-submodules" && \
    cd /ai-toolkit && \
    pip3 install --upgrade setuptools && \
    pip3 install -r requirements.txt && \
    echo "ai-toolkit" >> /installed_repos.txt

# Add X-Labs AI's ComfyUI extension for FLUX
RUN cd /ComfyUI/custom_nodes && \
    /clone_repo.sh "https://github.com/XLabs-AI/x-flux-comfyui.git" "./x-flux-comfyui" "main" && \
    cd x-flux-comfyui && \
    python3 setup.py && \
    echo "x-flux-comfyui" >> /installed_repos.txt

# Copy default train_lora.yaml file
COPY --chmod=644 ai-toolkit/train_lora.yaml /ai-toolkit/config/train_lora.yaml
COPY --chmod=755 ai-toolkit/caption_images.py /caption_images.py

# Copy input files, settings, and workflows
COPY --chmod=644 workflows/ /ComfyUI/user/default/workflows/
COPY --chmod=644 comfy.settings.json /ComfyUI/user/default/comfy.settings.json
COPY --chmod=644 character_sheet_example.png /ComfyUI/input/character_sheet_example.png
COPY --chmod=644 example_photo.png /ComfyUI/input/example_photo.png
COPY --chmod=644 example_photo_small.png /ComfyUI/input/example_photo_small.png
COPY --chmod=644 example_pose.png /ComfyUI/input/example_pose.png
COPY --chmod=644 example2.png /ComfyUI/input/example2.png
COPY --chmod=644 driving_video.mp4 /ComfyUI/input/driving_video.mp4

# Overwrite the default.json file in ComfyUI/web/templates for the new UI
RUN python3 /replaceDefaultGraph.py
COPY --chmod=644 defaultGraph.json /ComfyUI/web/templates/default.json

# Add model cache optimization script
COPY --chmod=755 setup_model_cache.sh /setup_model_cache.sh

# Add repository verification script
COPY --chmod=755 verify_repos.sh /verify_repos.sh

# Verify all repositories were installed correctly
RUN echo "Verifying repository installations..." && \
    REPO_COUNT=$(cat /installed_repos.txt | wc -l) && \
    echo "Successfully installed $REPO_COUNT repositories"

# Set working directory and expose ports
WORKDIR /workspace
EXPOSE 8188 8888 7860

CMD [ "/start.sh" ]
