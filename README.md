# Setup RepoAgent for GitHub Action 

This GitHub Action sets up PDM, installs dependencies, and runs RepoAgent with customizable configurations. It automatically generates documentation files based on your project and commits the changes to your repository.

## Configuration

Follow these steps to add secrets to your GitHub repository for use in GitHub Actions.

1. **Go to Your Repository**
   - Open your GitHub repository in the browser.

2. **Navigate to Settings**
   - Click on the **Settings** tab at the top of your repository's page.

3. **Open Secrets and Variables**
   - In the left sidebar, scroll down to **Security**.
   - Click on **Secrets and variables** to expand the options.
   - Select **Actions** under **Secrets and variables**.

4. **Add a New Repository Secret**
   - On the **Actions secrets and variables** page, locate the **Repository secrets** section.
   - Click the **New repository secret** button on the right.

5. **Enter Secret Details**  
   - As an example, if you need to add your OpenAI API key:
     - In the **Name** field, enter `OPENAI_API_KEY`.
     - In the **Value** field, paste your actual OpenAI API key.

6. **Save the Secret**
   - Click **Add secret** to save it.

7. **Repeat for Additional Secrets**
   - Repeat steps 4–6 for any additional secrets you need, like `OPENAI_BASE_URL`.

Once added, these secrets can be used as environment variables in your GitHub Actions workflow with the format `${{ secrets.SECRET_NAME }}`.

## Usage

To use this action, include it in your workflow YAML file like so:

```yaml
steps:
    - name: Run RepoAgent Action
    uses: Umpire2018/setup-repoagent@v1
    with:
        openai_api_key: "${{ secrets.OPENAI_API_KEY }}"
```

## Action Inputs

| Name               | Description                                                                                   | Required | Default                        |
|--------------------|-----------------------------------------------------------------------------------------------|----------|--------------------------------|
| `openai_base_url`  | The base URL for OpenAI API                                                                   | No       | `https://api.openai.com/v1`    |
| `openai_api_key`   | The API key for OpenAI API                                                                    | Yes      | -                              |
| `model`            | Model name to use for LLM, such as `gpt-4o-mini`                                              | No       | `gpt-4o-mini`                  |
| `temperature`      | Sampling temperature for generating responses. Lower values make the model more deterministic | No       | `0.2`                          |
| `request_timeout`  | Maximum request timeout in seconds for each API call                                          | No       | `60`                           |
| `target_repo`      | Directory path for the target repository to analyze                                           | No       | `${{ github.workspace }}`      |
| `hierarchy_name`   | The name of the directory to store project documentation records                              | No       | `.project_doc_record`          |
| `markdown_docs_name` | The directory name where markdown documentation is stored                                   | No       | `markdown_docs`                |
| `ignore_list`      | List of file paths to ignore during analysis                                                  | No       | `[]`                           |
| `language`         | The language to use for generated documentation                                               | No       | `English`                      |
| `max_thread_count` | Maximum number of threads to use during processing                                            | No       | `4`                            |
| `log_level`        | Log level for logging information (e.g., `INFO`, `DEBUG`, `ERROR`)                           | No       | `INFO`                         |

## Example Workflow with example secrets

```yaml
# .github/workflows/run-repoagent.yml
name: Use RepoAgent Action

on:
  workflow_dispatch:
  push:
  
permissions:
  contents: write  # This action requires write permissions for contents to push changes to the repository.
  
jobs:
  use-repoagent:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout main repository
        uses: actions/checkout@v4

      - name: Run RepoAgent Action
        uses: Umpire2018/setup-repoagent@v1
        with:
          openai_base_url: "${{ secrets.OPENAI_BASE_URL }}"
          openai_api_key: "${{ secrets.OPENAI_API_KEY }}"
```

![image](https://github.com/user-attachments/assets/12d07901-2c1e-4c70-b3b5-4174c600c6a6)
