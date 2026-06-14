#!/bin/bash
set -e

HOME_DIR=/home/aequitas/.evmosd

if [ ! -f "$HOME_DIR/config/genesis.json" ]; then
    evmosd init aequitas-node --chain-id aequitas_9001-1 --home $HOME_DIR
    
    python3 -c "
import json
with open('$HOME_DIR/config/genesis.json') as f:
    g = json.load(f)
g['app_state']['staking']['params']['bond_denom'] = 'aevmos'
g['app_state']['gov']['params']['min_deposit'][0]['denom'] = 'aevmos'
with open('$HOME_DIR/config/genesis.json', 'w') as f:
    json.dump(g, f)
"
    
    echo "$VALIDATOR_MNEMONIC" | evmosd keys add aequitas-validator --keyring-backend test --recover --home $HOME_DIR
    
    VALIDATOR_ADDR=$(evmosd keys show aequitas-validator --keyring-backend test --home $HOME_DIR -a)
    
    evmosd add-genesis-account $VALIDATOR_ADDR 10000000000000000000000aevmos --keyring-backend test --home $HOME_DIR
    evmosd gentx aequitas-validator 1000000000000000000aevmos --chain-id aequitas_9001-1 --keyring-backend test --home $HOME_DIR
    evmosd collect-gentxs --home $HOME_DIR
    
    sed -i 's/enable = false/enable = true/' $HOME_DIR/config/app.toml
    sed -i 's/address = "127.0.0.1:8545"/address = "0.0.0.0:8545"/' $HOME_DIR/config/app.toml
    sed -i 's/ws-address = "127.0.0.1:8546"/ws-address = "0.0.0.0:8546"/' $HOME_DIR/config/app.toml
    sed -i 's/laddr = "tcp:\/\/127.0.0.1:26657"/laddr = "tcp:\/\/0.0.0.0:26657"/' $HOME_DIR/config/config.toml
    sed -i 's/seeds = ".*"/seeds = ""/' $HOME_DIR/config/config.toml
fi

exec evmosd start --home $HOME_DIR --json-rpc.enable --json-rpc.address 0.0.0.0:8545 --json-rpc.ws-address 0.0.0.0:8546
