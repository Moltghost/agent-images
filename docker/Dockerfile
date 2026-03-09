# =============================================================================
# MoltGhost Agent — Pre-baked Docker Image
# =============================================================================
# Contains: CUDA 12.2 + Ollama + LLM model + cloudflared + Node.js 22 + OpenClaw
# Base: NVIDIA CUDA 12.2 runtime (GPU drivers provided by RunPod host)
#
# Build (default qwen3:8b):
#   docker build --platform linux/amd64 -t moltghost/moltghost-agent:latest -f docker/Dockerfile .
#
# Build (custom model):
#   docker build --platform linux/amd64 --build-arg OLLAMA_MODEL=phi4-mini -t moltghost/moltghost-agent:phi4-mini -f docker/Dockerfile .
#
# Push:
#   docker push moltghost/moltghost-agent:latest
# =============================================================================

FROM nvidia/cuda:12.2.0-runtime-ubuntu22.04

# Configurable model — override with --build-arg OLLAMA_MODEL=phi4-mini
ARG OLLAMA_MODEL=qwen3:8b

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------
# 1. System dependencies
# ---------------------------------------------------------------------------
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    curl wget git jq ca-certificates zstd pciutils openssh-server \
    gnupg2 software-properties-common && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# 2. Node.js 22 + pnpm (required by OpenClaw)
# ---------------------------------------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g pnpm && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# 3. cloudflared (Cloudflare Tunnel client)
# ---------------------------------------------------------------------------
RUN curl -fsSL -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb \
    -o /tmp/cloudflared.deb && \
    dpkg -i /tmp/cloudflared.deb && \
    rm -f /tmp/cloudflared.deb

# ---------------------------------------------------------------------------
# 4. Ollama (LLM runtime)
# ---------------------------------------------------------------------------
RUN curl -fsSL https://ollama.com/install.sh | bash

# ---------------------------------------------------------------------------
# 5. Pull LLM model — baked into image
#    NOTE: No GPU during docker build — that's fine, we only need to
#    download the model weights. GPU loading happens at runtime.
# ---------------------------------------------------------------------------
RUN ollama serve & \
    SERVER_PID=$! && \
    # Wait until Ollama API is actually ready (up to 30s)
    for i in $(seq 1 30); do \
    curl -sf http://localhost:11434/api/tags > /dev/null 2>&1 && break; \
    sleep 1; \
    done && \
    # Pull the model
    ollama pull ${OLLAMA_MODEL} && \
    # Verify model is actually present
    ollama list | grep -q "${OLLAMA_MODEL}" && \
    echo "✅ ${OLLAMA_MODEL} model verified in image" && \
    # Show model size for build log
    du -sh /root/.ollama/models/ 2>/dev/null || true && \
    kill $SERVER_PID 2>/dev/null; \
    wait $SERVER_PID 2>/dev/null || true

# Persist model name for runtime scripts
ENV OLLAMA_MODEL=${OLLAMA_MODEL}

# ---------------------------------------------------------------------------
# 6. Clone + build OpenClaw (baked into image for fast boot)
# ---------------------------------------------------------------------------
RUN git clone --depth 1 https://github.com/openclaw/openclaw.git /opt/openclaw-src && \
    cd /opt/openclaw-src && \
    npm install --prefer-offline > /var/log/openclaw-npm.log 2>&1 && \
    npm run build > /var/log/openclaw-build.log 2>&1 && \
    test -f /opt/openclaw-src/dist/index.js && \
    echo "✅ OpenClaw built successfully" && \
    (npm run ui:install > /dev/null 2>&1 || true) && \
    (npm run ui:build > /dev/null 2>&1 || true) && \
    npm cache clean --force && \
    rm -rf /tmp/* /root/.npm

# ---------------------------------------------------------------------------
# 7. Create directories for runtime
# ---------------------------------------------------------------------------
RUN mkdir -p /var/log /root/.ssh /root/.openclaw/workspace /root/.openclaw/agents/main/agent && \
    chmod 700 /root/.ssh

# Environment defaults
ENV OLLAMA_HOST=0.0.0.0:11434
ENV OLLAMA_KEEP_ALIVE=-1
ENV HOME=/root
ENV PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:$PATH"

# Expose ports: OpenClaw (3000), Ollama (11434), SSH (22)
EXPOSE 3000 11434 22

# Default command (overridden by RunPod dockerArgs)
CMD ["bash"]
