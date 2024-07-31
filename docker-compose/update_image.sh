#!/bin/bash

# Define the new tag
NEW_TAG="5.5.1582"

# List of images to update
IMAGES=(
    "sourcegraph/migrator"
    "sourcegraph/frontend"
    "sourcegraph/gitserver"
    "sourcegraph/search-indexer"
    "sourcegraph/indexed-searcher"
    "sourcegraph/searcher"
    "sourcegraph/precise-code-intel-worker"
    "sourcegraph/repo-updater"
    "sourcegraph/worker"
    "sourcegraph/syntax-highlighter"
    "sourcegraph/symbols"
    "sourcegraph/prometheus"
    "sourcegraph/grafana"
    "sourcegraph/cadvisor"
    "sourcegraph/node-exporter"
    "sourcegraph/postgres-12-alpine"
    "sourcegraph/postgres_exporter"
    "sourcegraph/codeintel-db"
    "sourcegraph/codeinsights-db"
    "sourcegraph/blobstore"
    "sourcegraph/redis-cache"
    "sourcegraph/redis-store"
    "sourcegraph/opentelemetry-collector"
)

# Function to pull the image and get the SHA digest
get_image_sha() {
    local image=$1
    local tag=$2
    local full_image="index.docker.io/$image:$tag"
    local digest=$(docker pull $full_image 2>/dev/null | grep "Digest:" | awk '{print $2}')
    if [ -n "$digest" ]; then
        echo "$digest"
        return 0
    else
        return 1
    fi
}

# Update images in the docker-compose file if they exist
for image in "${IMAGES[@]}"; do
    digest=$(get_image_sha $image $NEW_TAG)
    if [ $? -eq 0 ]; then
        sed -i.bak -E "s|($image):[^@]+@sha256:[a-f0-9]+|\1:$NEW_TAG@$digest|g" docker-compose.yaml
        echo "Updated $image to $NEW_TAG@$digest"
    else
        echo "Skipping update for $image as it does not exist with tag $NEW_TAG."
    fi
done

echo "Image update process completed."
