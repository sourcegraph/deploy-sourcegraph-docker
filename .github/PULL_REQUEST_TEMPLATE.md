<!-- description here -->

### Checklist

<!--
  Kubernetes and Docker Compose MUST be kept in sync. You should not merge a change here
  without a corresponding change in the other repository, unless it truly is specific to
  this repository. If uneeded, add link or explanation of why it is not needed here.
-->
* [ ] Sister [deploy-sourcegraph](https://github.com/sourcegraph/deploy-sourcegraph) change:
* [ ] If this change introduces or removes a service, add this service to `tools/update-docker-tags.sh`
* [ ] All images have a valid tag and SHA256 sum
