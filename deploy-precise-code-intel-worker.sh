#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Handles conversion of uploaded precise code intelligence bundles.
#
# Ports exposed to other Sourcegraph services: 3188/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=precise-code-intel-worker \
    --network=sourcegraph \
    --restart=always \
    --cpus=2 \
    --memory=4g \
    -e 'PRECISE_CODE_INTEL_BUNDLE_MANAGER_URL=http://precise-code-intel-bundle-manager:3187' \
    -e 'SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090' \
    # If these variables are updated, they must also be updated in the
    # deploy-frontend and deploy-frontend-internal containers as well.
	-e PRECISE_CODE_INTEL_UPLOAD_BACKEND=S3 \
	-e PRECISE_CODE_INTEL_UPLOAD_BUCKET=lsif-uploads \
	-e PRECISE_CODE_INTEL_UPLOAD_MANAGE_BUCKET=true \
	-e AWS_ACCESS_KEY_ID='AKIAIOSFODNN7EXAMPLE' \
	-e AWS_SECRET_ACCESS_KEY='wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY' \
	-e AWS_ENDPOINT=http://minio:9000 \
	-e AWS_REGION=us-east-1 \
	-e AWS_S3_FORCE_PATH_STYLE=true \
    index.docker.io/sourcegraph/precise-code-intel-worker:3.21.2@sha256:77973d2d7b07702c2d9e456098b71c430b6c08966b3b028409d68c7837e5a950

echo "Deployed precise-code-intel-worker service"
