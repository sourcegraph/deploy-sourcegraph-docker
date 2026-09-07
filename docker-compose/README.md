# Sourcegraph with Docker Compose deployment reference

This directory contains the Sourcegraph with Docker Compose deployment reference.

To learn more about deploying, configuring, and upgrading a Sourcegraph with Docker Compose installation, please refer to our documentation: [Sourcegraph with Docker Compose](https://docs.sourcegraph.com/admin/install/docker-compose)

## Shared object storage

Sourcegraph requires an object storage to work. [Learn more](https://sourcegraph.com/docs/self-hosted/external-services/object-storage#sourcegraph-bucket).

[`sourcegraph-uploads.env`](sourcegraph-uploads.env) configures shared Sourcegraph object storage for six services: frontend, worker, precise code intel, syntactic code intel, gitserver, and searcher. It uses a bundled blobstore by default to get you started, but we strongly recommend using S3 or GCS.

To use an external S3 or GCS bucket, update that file with the correct settings.

For GCS, embedding the service-account JSON with `SOURCEGRAPH_UPLOAD_GOOGLE_APPLICATION_CREDENTIALS_FILE_CONTENT` avoids requiring an identical credential-file mount in every container. If `SOURCEGRAPH_UPLOAD_GOOGLE_APPLICATION_CREDENTIALS_FILE` is used instead, mount that path into every consumer.
