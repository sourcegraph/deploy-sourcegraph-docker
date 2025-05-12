# Here you can specify the number of service replicas to deploy.
NUM_GITSERVER=1
NUM_SEARCHER=1
NUM_INDEXED_SEARCH=1
NUM_FRONTEND=3

addresses() { for i in $(seq 0 $(($2 - 1))); do echo -n "$1$i$3 "; done; }
