#!/bin/bash
# =============================================================================
# Build & Push MoltGhost Agent Docker Image — Phi-4 Mini (3.8B)
# =============================================================================
# Run this on a machine with Docker installed.
#
# Usage:
#   ./docker/build-and-push-phi4-mini.sh                          # default tag
#   ./docker/build-and-push-phi4-mini.sh myrepo/agent:phi4-mini   # custom tag
# =============================================================================

set -e

IMAGE_TAG="${1:-moltghost/moltghost-agent:phi4-mini}"

echo "============================================="
echo " Building MoltGhost Agent Docker Image"
echo " Model: phi4-mini (3.8B)"
echo " Tag: $IMAGE_TAG"
echo "============================================="
echo ""
echo "This will take ~10 minutes (downloads ~2.5GB model)."
echo ""

# Build
docker build \
  --build-arg OLLAMA_MODEL=phi4-mini \
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
