#!/bin/bash
set -e

# Log start of the RepoAgent Action
echo "Starting RepoAgent Action..."

# Set environment variables from GitHub Action inputs
export OPENAI_API_KEY="${INPUT_OPENAI_API_KEY}"

# Clone the RepoAgent repository refactor branch into a temporary directory
echo "Cloning RepoAgent repository into a temporary directory..."
TEMP_DIR=$(mktemp -d) || { echo "Failed to create temporary directory"; exit 1; }
git clone https://github.com/OpenBMB/RepoAgent.git "$TEMP_DIR"

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

command="repoagent run"
command+=" --base-url ${INPUT_OPENAI_BASE_URL}"
command+=" --model ${INPUT_MODEL}"
command+=" --temperature ${INPUT_TEMPERATURE}"
command+=" --request-timeout ${INPUT_REQUEST_TIMEOUT}"
command+=" --hierarchy-path ${INPUT_HIERARCHY_PATH}"
command+=" --markdown-docs-path ${INPUT_MARKDOWN_DOCS_PATH}"
command+=" --ignore-list ${INPUT_IGNORE_LIST}"
command+=" --language ${INPUT_LANGUAGE}"
command+=" --max-thread-count ${INPUT_MAX_THREAD_COUNT}"
command+=" --log-level ${INPUT_LOG_LEVEL}"

# Add the --print-hierarchy parameter only if INPUT_PRINT_HIERARCHY is "true"
if [[ "${INPUT_PRINT_HIERARCHY}" == "true" ]]; then
  command+=" --print-hierarchy"
fi

echo "Running: $command"
eval $command || { echo "RepoAgent run failed"; exit 1; }

# Set Git user identity for committing changes in CI environment
git config --global user.email "action@github.com"
git config --global user.name "GitHub Action"

# Commit changes
git add .
if git diff --cached --quiet; then
  echo "No changes to commit."
else
  if git commit -m "chore(repoagent): automated changes by RepoAgent Action"; then
    echo "Changes committed."

    # Pull latest changes and handle conflicts automatically
    export GIT_MERGE_AUTOEDIT=no
    if ! git pull --rebase origin "$(git rev-parse --abbrev-ref HEAD)"; then
      echo "Conflict detected. Resolving conflicts automatically..."

      # Resolve conflicts for specified directories using environment variables
      git checkout --ours "${INPUT_HIERARCHY_PATH}" 
      git checkout --ours "${INPUT_MARKDOWN_DOCS_PATH}"

      # Mark conflicts as resolved
      git add "${INPUT_HIERARCHY_PATH}" "${INPUT_MARKDOWN_DOCS_PATH}"

      # Continue the rebase
      GIT_EDITOR=true git rebase --continue || { echo "Failed to continue rebase after resolving conflicts."; exit 1; }
    fi

    # Push changes to the remote repository
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
