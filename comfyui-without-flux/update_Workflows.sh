#!/bin/bash

# Define the URL and the target file
URL="https://raw.githubusercontent.com/chris01b/ComfyUI_template/refs/heads/main/comfyui-without-flux/download_Workflows.sh"
FILE="download_Workflows.sh"

# Download the script, overwriting if it already exists
curl -O $URL

# Make the downloaded script executable
chmod +x $FILE

# Run the downloaded script
./$FILE
