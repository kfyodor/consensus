### Consensus (not raft)

Cluster consensus algorithm emulation written in pure Ruby using Celluloid actor library. Raft-ish (maybe).

## How to run this?

1. ```cd YOUR_APP_PATH/consensus```
2. ```bundle install```
3. Check out (or modify) config/nodes.yml for node ids.
4. ```./bin consensus NODE_ID``` in each terminal tab.
5. Watch how nodes talk with each other.