#!/bin/bash
# =============================================================================
# Build & Push MoltGhost Agent Docker Image (default: qwen3:8b)
# =============================================================================
# Run this on a machine with Docker installed.
# For best results, use a machine with fast internet (RunPod CPU pod works).
#
# Usage:
#   ./docker/build-and-push.sh                    # uses default tag + qwen3:8b
#   ./docker/build-and-push.sh myrepo/agent:v1    # custom tag
# =============================================================================

set -e

IMAGE_TAG="${1:-moltghost/moltghost-agent:latest}"

echo "============================================="
echo " Building MoltGhost Agent Docker Image"
echo " Model: qwen3:8b (default)"
echo " Tag: $IMAGE_TAG"
echo "============================================="
echo ""
echo "This will take ~20 minutes (downloads ~5GB model + builds OpenClaw)."
echo ""

# Build
docker build \
  -t "$IMAGE_TAG" \
  -f docker/Dockerfile \
  --progress=plain \
  .

echo ""
echo "============================================="
echo " Build complete! Image: $IMAGE_TAG"
echo "============================================="
echo ""

# Check image size
docker images "$IMAGE_TAG" --format "Size: {{.Size}}"

echo ""
read -p "Push to Docker Hub? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Pushing $IMAGE_TAG ..."
  docker push "$IMAGE_TAG"
  echo "Done! Image pushed to Docker Hub."
else
  echo "Skipped push. Run 'docker push $IMAGE_TAG' when ready."
fi
