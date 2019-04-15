# Here you can specify the number of service replicas to deploy.
NUM_GITSERVER=18
NUM_SEARCHER=16
NUM_SYMBOLS=4
NUM_FRONTEND=3

addresses() { for i in $(seq 0 $(($2 - 1))); do echo -n "$1$i$3 "; done }
