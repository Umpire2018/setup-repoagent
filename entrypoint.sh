#!/bin/bash
set -e

# Log start of the RepoAgent Action
echo "Starting RepoAgent Action..."

# Set environment variables from GitHub Action inputs
export OPENAI_BASE_URL="${INPUT_OPENAI_BASE_URL}"
export OPENAI_API_KEY="${INPUT_OPENAI_API_KEY}"
export MODEL="${INPUT_MODEL}"
export TEMPERATURE="${INPUT_TEMPERATURE}"
export REQUEST_TIMEOUT="${INPUT_REQUEST_TIMEOUT}"
export TARGET_REPO="${INPUT_TARGET_REPO}"
export HIERARCHY_NAME="${INPUT_HIERARCHY_NAME}"
export MARKDOWN_DOCS_NAME="${INPUT_MARKDOWN_DOCS_NAME}"
export IGNORE_LIST="${INPUT_IGNORE_LIST}"
export LANGUAGE="${INPUT_LANGUAGE}"
export MAX_THREAD_COUNT="${INPUT_MAX_THREAD_COUNT}"
export LOG_LEVEL="${INPUT_LOG_LEVEL}"

# Clone the RepoAgent repository refactor branch into a temporary directory
echo "Cloning RepoAgent repository into a temporary directory..."
TEMP_DIR=$(mktemp -d)
git clone --branch refactor https://github.com/Umpire2018/RepoAgent.git "$TEMP_DIR"

# Set up PDM and build dependencies
echo "Setting up PDM and installing dependencies..."
cd "$TEMP_DIR"
pdm build --dest /action/dist || { echo "PDM build failed"; exit 1; }

# Return to /action directory and clean up temporary directory
cd /action
rm -rf "$TEMP_DIR"

# Create a virtual environment with PDM using a specified name
ENV_NAME="repoagent-env"
pdm venv create --with-pip --name "$ENV_NAME" || { echo "Failed to create virtual environment"; exit 1; }

# Activate the virtual environment
eval "$(pdm venv activate $ENV_NAME)" || { echo "Failed to activate virtual environment"; exit 1; }

# Confirm the virtual environment is activated
echo "Activated virtual environment: $(which python)"

# Install the built package using pip from the dist directory
pip install dist/*.whl || { echo "Failed to install package"; exit 1; }

# Set the target repository path and configure Git safe directory setting
export TARGET_REPO="${GITHUB_WORKSPACE}"
git config --global --add safe.directory "${TARGET_REPO}"

# Run RepoAgent in the target repository
echo "Running RepoAgent with TARGET_REPO set to ${TARGET_REPO}..."
cd "${TARGET_REPO}"
repoagent run || { echo "RepoAgent run failed"; exit 1; }

# Set Git user identity for committing changes in CI environment
git config --global user.email "action@github.com"
git config --global user.name "GitHub Action"

# Check if there are staged changes to commit
if git diff --cached --quiet; then
  echo "No changes to commit."
else
  if git commit -m "chore(repoagent): automated changes by RepoAgent Action"; then
    echo "Changes committed."

    # Pull the latest changes to avoid conflicts before pushing
    echo "Pulling latest changes from the remote repository..."
    git pull --rebase origin "$(git rev-parse --abbrev-ref HEAD)"

    # Push changes to the remote repository
    echo "Pushing changes to the repository..."
    if git push origin "$(git rev-parse --abbrev-ref HEAD)"; then
      echo "Changes pushed successfully."
    else
      echo "Failed to push changes. Please check for conflicts."
      exit 1
    fi
  else
    echo "Failed to commit changes."
    exit 1
  fi
fi

echo "RepoAgent Action completed."
