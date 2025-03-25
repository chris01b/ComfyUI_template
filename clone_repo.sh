#!/bin/bash

# Helper script for cloning git repositories with proper error handling
# Usage: clone_repo.sh <repo_url> <destination_path> <branch_or_tag> [extra_args]

REPO_URL=$1
DEST_PATH=$2
BRANCH=${3:-"main"}
EXTRA_ARGS=${4:-""}

echo "Cloning repository: $REPO_URL to $DEST_PATH (branch/tag: $BRANCH)"

# Check if destination already exists
if [ -d "$DEST_PATH" ]; then
    echo "Warning: Destination directory $DEST_PATH already exists"
    echo "Attempting to update instead of cloning..."
    
    # Try to update the existing repo
    cd "$DEST_PATH"
    # Reset any local changes that may cause conflicts
    git reset --hard
    git fetch origin "$BRANCH"
    # Only try to checkout if the fetch succeeded
    if [ $? -eq 0 ]; then
        git checkout "$BRANCH"
        git pull origin "$BRANCH"
        echo "Repository $REPO_URL updated successfully to $BRANCH"
        exit 0
    else
        echo "Failed to update repository, removing and cloning fresh"
        cd ..
        rm -rf "$DEST_PATH"
    fi
fi

# Create parent directory if needed
mkdir -p $(dirname "$DEST_PATH")

# Clone with shallow depth for faster cloning and smaller size
# The --depth 1 option creates a shallow clone with only the latest commit
# The --single-branch option clones only the specified branch
CLONE_CMD="git clone --depth 1 --single-branch --branch $BRANCH $REPO_URL $DEST_PATH $EXTRA_ARGS"

echo "Running: $CLONE_CMD"
eval $CLONE_CMD

# Check if clone was successful
if [ $? -ne 0 ]; then
    echo "Failed to clone repository: $REPO_URL (branch: $BRANCH)"
    
    # Try without branch specification as fallback (some repos use 'master' instead of 'main')
    if [ "$BRANCH" = "main" ]; then
        echo "Trying to clone with 'master' branch instead..."
        git clone --depth 1 --single-branch --branch master $REPO_URL $DEST_PATH $EXTRA_ARGS
        
        if [ $? -ne 0 ]; then
            echo "Trying to clone without branch specification..."
            git clone --depth 1 $REPO_URL $DEST_PATH $EXTRA_ARGS
            
            if [ $? -ne 0 ]; then
                echo "ERROR: All attempts to clone $REPO_URL failed."
                exit 1
            fi
        fi
    else
        # If a specific branch/tag was requested, try without branch specification
        echo "Trying to clone without branch specification..."
        git clone --depth 1 $REPO_URL $DEST_PATH $EXTRA_ARGS
        
        if [ $? -eq 0 ]; then
            # Try to checkout the specified branch/tag
            cd "$DEST_PATH"
            git checkout $BRANCH
            if [ $? -ne 0 ]; then
                echo "WARNING: Failed to checkout $BRANCH, using default branch instead."
            fi
        else
            echo "ERROR: All attempts to clone $REPO_URL failed."
            exit 1
        fi
    fi
fi

echo "Successfully cloned repository: $REPO_URL to $DEST_PATH"
exit 0 