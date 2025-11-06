#!/bin/sh
set -e

IMAGE_NAME=csv-processor:latest
CONTAINER_NAME=csv-processor
PORT=8080

build_image() {
  START=$(date +%s)

  docker build -t $IMAGE_NAME .

  END=$(date +%s)
  BUILD_TIME=$((END-START))
  echo "Build time: $BUILD_TIME seconds"
}

image_size() {
  SZ=$(docker image inspect $IMAGE_NAME --format '{{.Size}}')
  SZ_MB=$((SZ/1024/1024))
  echo "Image size: $SZ_MB MB"
}

start_container() {
  docker compose up -d
  # Wait for healthcheck (timeout 30s)
  for i in $(seq 1 30); do
    STATUS=$(docker inspect --format='{{.State.Health.Status}}' $CONTAINER_NAME 2>/dev/null || echo "starting")
    if [ "$STATUS" = "healthy" ]; then
      break
    fi
    sleep 1
  done
  echo "Container health: $STATUS"
}

container_memory() {
  MEM=$(docker stats --no-stream --format '{{.MemUsage}}' $CONTAINER_NAME | awk '{print $1}')
  echo "Container memory usage: $MEM"
}

container_responsiveness() {
  RESP="$(curl -w '%{time_total}' -s -o /dev/null http://localhost:$PORT/health)"
  echo "Container /health endpoint response time: ${RESP}s"
}

deploy() {
  echo "--- Build and Metrics ---"
  build_image
  image_size

  echo "--- Start and Health ---"
  start_container
  container_memory
  container_responsiveness

  echo "--- Cleanup ---"
  docker compose down
}

if [ "$1" = "baseline" ]; then
  echo "(Baseline run: run this before optimizing Dockerfile/compose.)"
fi

deploy
chmod +x deployment_metrics.sh
