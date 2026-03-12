FROM python:3.11-slim

WORKDIR /app

# Copy project files
COPY ./radkit-mcp-server-community/ .

# Install dependencies
RUN pip install --no-cache-dir -e . \
    --extra-index-url https://radkit.cisco.com/pip \
    --trusted-host radkit.cisco.com

# Run server
CMD ["python", "-m", "radkit_mcp.server"]
