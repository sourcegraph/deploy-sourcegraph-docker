# Sourcegraph with Docker Compose deployment reference

This directory contains the Sourcegraph with Docker Compose deployment reference.

To learn more about deploying, configuring, and upgrading a Sourcegraph with Docker Compose installation, please refer to our documentation: [Sourcegraph with Docker Compose](https://docs.sourcegraph.com/admin/install/docker-compose)

## Shared object storage

[`sourcegraph-uploads.env`](sourcegraph-uploads.env) configures shared Sourcegraph object storage for six services: frontend (both frontend containers), worker, precise Code Intel, syntactic Code Intel, gitserver, and searcher. It uses the bundled blobstore by default.

To use an external S3 or GCS bucket, update that file so every consumer receives the same settings. Containers do not inherit environment variables or cloud credentials from the host or from other containers, so credentials must be provided explicitly in this file (or by an equivalent Compose override applied to every consumer).

Common settings are:

- `SOURCEGRAPH_UPLOAD_BACKEND`: `S3`, `GCS`, or `blobstore`
- `SOURCEGRAPH_UPLOAD_BUCKET`
- `SOURCEGRAPH_UPLOAD_MANAGE_BUCKET`
- S3: `SOURCEGRAPH_UPLOAD_AWS_REGION`, `SOURCEGRAPH_UPLOAD_AWS_ENDPOINT`, `SOURCEGRAPH_UPLOAD_AWS_USE_PATH_STYLE`, `SOURCEGRAPH_UPLOAD_AWS_ACCESS_KEY_ID`, `SOURCEGRAPH_UPLOAD_AWS_SECRET_ACCESS_KEY`, and optionally `SOURCEGRAPH_UPLOAD_AWS_SESSION_TOKEN` or `SOURCEGRAPH_UPLOAD_AWS_USE_EC2_ROLE_CREDENTIALS`
- GCS: `SOURCEGRAPH_UPLOAD_GCP_PROJECT_ID` and `SOURCEGRAPH_UPLOAD_GOOGLE_APPLICATION_CREDENTIALS_FILE_CONTENT`

For GCS, embedding the service-account JSON with `SOURCEGRAPH_UPLOAD_GOOGLE_APPLICATION_CREDENTIALS_FILE_CONTENT` avoids requiring an identical credential-file mount in every container. If `SOURCEGRAPH_UPLOAD_GOOGLE_APPLICATION_CREDENTIALS_FILE` is used instead, mount that path into every consumer.
