# Use the official Python 3.12 slim image as the base image
FROM python:3.12-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Install system dependencies, keeping apt cache for faster repeated builds
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Install PDM (Python Dependency Manager)
RUN curl -sSL https://pdm-project.org/install-pdm.py | python3 -

# Add PDM installation path to PATH
ENV PATH=/root/.local/bin:$PATH

# Copy the entrypoint script and make it executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set the entrypoint to execute the script on container start
ENTRYPOINT ["/entrypoint.sh"]
