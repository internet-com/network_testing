#! /bin/bash

MACH_PREFIX=$1
N=$2
NODE_DIRS=$3
BLOCKSIZE=$4
N_TXS=$5
RESULTS=$6

# initialize directories
mintnet init --machines "${MACH_PREFIX}[1-${N}]" chain --app-hash nil $NODE_DIRS

# drop the config file
cat > $NODE_DIRS/chain_config.toml << EOL
# This is a TOML config file.
# For more information, see https://github.com/toml-lang/toml

proxy_app = "nilapp"
moniker = "anonymous"
node_laddr = "0.0.0.0:46656"
seeds = ""
fast_sync = false
db_backend = "leveldb"
log_level = "notice"
rpc_laddr = "0.0.0.0:46657"

preload_txs=$N_TXS
block_size=$BLOCKSIZE
timeout_commit=1 # don't wait for votes on commit; assume synchrony for everything else
mempool_recheck=false # don't care about app state
cswal_light=true # don't write block part messages
EOL

# copy the config file into every dir
for i in `seq 1 $N`; do
		cp $NODE_DIRS/chain_config.toml $NODE_DIRS/${MACH_PREFIX}$i/core/config.toml
done

# overwrite the init file so we can pick tendermint branch
cat > $NODE_DIRS/core/init.sh << EOL
#! /bin/bash
TMREPO="github.com/tendermint/tendermint"
BRANCH="params"

go get -d \$TMREPO/cmd/tendermint
cd \$GOPATH/src/\$TMREPO
git fetch origin \$BRANCH
git checkout \$BRANCH
make install

tendermint node --seeds="\$TMSEEDS" --moniker="\$TMNAME" --proxy_app="\$PROXYAPP"
EOL

# start the nodes
mintnet start --machines "$MACH_PREFIX[1-${N}]" --no-tmsp bench_app $NODE_DIRS
