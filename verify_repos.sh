#!/bin/bash

# This script verifies and repairs repository installations
# It can be run manually to fix issues with missing or corrupt repositories

echo "🔍 Verifying repository installations..."

# List of essential repositories and their details
# Format: "repo_url|destination_path|branch|extra_args"
ESSENTIAL_REPOS=(
    "https://github.com/comfyanonymous/ComfyUI.git|/workspace/ComfyUI|main|"
    "https://github.com/ltdrdata/ComfyUI-Manager.git|/workspace/ComfyUI/custom_nodes/ComfyUI-Manager|main|"
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git|/workspace/ComfyUI/custom_nodes/ComfyUI-Custom-Scripts|main|"
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git|/workspace/ComfyUI/custom_nodes/ComfyUI-Impact-Pack|main|"
    "https://github.com/flowtyone/ComfyUI-Flowty-LDSR.git|/workspace/ComfyUI/custom_nodes/ComfyUI-Flowty-LDSR|main|"
    "https://github.com/kijai/ComfyUI-SUPIR.git|/workspace/ComfyUI/custom_nodes/ComfyUI-SUPIR|main|"
)

# Optional repositories - add more here if needed
OPTIONAL_REPOS=(
    "https://github.com/XLabs-AI/x-flux-comfyui.git|/workspace/ComfyUI/custom_nodes/x-flux-comfyui|main|"
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git|/workspace/ComfyUI/custom_nodes/ComfyUI-VideoHelperSuite|main|"
    "https://github.com/PowerHouseMan/ComfyUI-AdvancedLivePortrait.git|/workspace/ComfyUI/custom_nodes/ComfyUI-AdvancedLivePortrait|main|"
)

# Function to verify and repair a repository
verify_repo() {
    local repo_info=$1
    local force_reinstall=$2
    
    # Split the repo info by |
    IFS='|' read -r repo_url dest_path branch extra_args <<< "$repo_info"
    
    local repo_name=$(basename "$dest_path")
    echo "Checking $repo_name..."
    
    # Determine if repo needs reinstallation
    local needs_reinstall=0
    
    # Force reinstall if requested
    if [ "$force_reinstall" = "1" ]; then
        needs_reinstall=1
        echo "⚙️ Forcing reinstall of $repo_name"
    # Check if repo directory exists
    elif [ ! -d "$dest_path" ]; then
        needs_reinstall=1
        echo "⚠️ Repository $repo_name not found, will install"
    # Check if .git directory exists within repo
    elif [ ! -d "$dest_path/.git" ]; then
        needs_reinstall=1
        echo "⚠️ Repository $repo_name missing .git directory, will reinstall"
    fi
    
    # Reinstall repository if needed
    if [ $needs_reinstall -eq 1 ]; then
        echo "⬇️ Installing $repo_name..."
        
        # Remove existing directory if it exists
        if [ -d "$dest_path" ]; then
            echo "🗑️ Removing existing directory $dest_path"
            rm -rf "$dest_path"
        fi
        
        # Clone the repository
        if [ -f "/clone_repo.sh" ]; then
            /clone_repo.sh "$repo_url" "$dest_path" "$branch" "$extra_args"
            result=$?
        else
            # Fallback to direct git command if clone_repo.sh doesn't exist
            mkdir -p $(dirname "$dest_path")
            git clone --depth 1 --single-branch --branch "$branch" $repo_url "$dest_path" $extra_args
            result=$?
        fi
        
        # Check if install was successful
        if [ $result -eq 0 ]; then
            echo "✅ Successfully installed $repo_name"
            
            # Install requirements if they exist
            if [ -f "$dest_path/requirements.txt" ]; then
                echo "📦 Installing requirements for $repo_name"
                cd "$dest_path"
                pip3 install -r requirements.txt
                
                # Run setup.py if it exists
                if [ -f "$dest_path/setup.py" ]; then
                    echo "🔧 Running setup.py for $repo_name"
                    python3 setup.py
                fi
                
                # Run install.py if it exists
                if [ -f "$dest_path/install.py" ]; then
                    echo "🔧 Running install.py for $repo_name"
                    python3 install.py
                fi
            fi
            
            # Add to installed_repos.txt
            echo "$repo_name" >> /installed_repos.txt
            return 0
        else
            echo "❌ Failed to install $repo_name"
            return 1
        fi
    else
        echo "✅ Repository $repo_name is properly installed"
        return 0
    fi
}

# Create or clean the installed_repos file
if [ ! -f "/installed_repos.txt" ]; then
    touch /installed_repos.txt
fi

# Process command line arguments
FORCE_REINSTALL=0
VERIFY_ESSENTIAL_ONLY=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --force|-f)
            FORCE_REINSTALL=1
            shift
            ;;
        --essential-only|-e)
            VERIFY_ESSENTIAL_ONLY=1
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--force|-f] [--essential-only|-e]"
            echo "  --force, -f: Force reinstallation of all repositories"
            echo "  --essential-only, -e: Only verify essential repositories"
            exit 1
            ;;
    esac
done

# Verify essential repositories
echo "🔍 Verifying essential repositories..."
for repo in "${ESSENTIAL_REPOS[@]}"; do
    verify_repo "$repo" $FORCE_REINSTALL
done

# Verify optional repositories if not essential only
if [ $VERIFY_ESSENTIAL_ONLY -eq 0 ]; then
    echo "🔍 Verifying optional repositories..."
    for repo in "${OPTIONAL_REPOS[@]}"; do
        verify_repo "$repo" $FORCE_REINSTALL
    done
fi

# Count verified repositories
REPO_COUNT=$(cat /installed_repos.txt | sort | uniq | wc -l)
echo "✅ Verification complete: $REPO_COUNT repositories installed"

# Provide guidance for next steps
echo ""
echo "📋 Next steps:"
echo "1. If any repositories were reinstalled, restart ComfyUI"
echo "2. If you're still having issues, try running with the --force flag:"
echo "   bash /verify_repos.sh --force"
echo "" 