#!/usr/bin/dumb-init /bin/bash
set -m

export VAULT_ADDR=${VAULT_ADDR:-http://127.0.0.1:8200}
export VAULT_TOKEN=$VAULT_DEV_ROOT_TOKEN_ID
export VAULT_LOCAL_CONFIG=${VAULT_LOCAL_CONFIG:-'{"backend":{"inmem":{}}}'}
export VAULT_DATA_DIR=${VAULT_DATA_DIR:-/docker-entrypoint-init}

exec docker-entrypoint.sh server -dev &

until vault status; do sleep 0.25; done

# set the VAULT_LOCAL_DATA environment variable to pass some vault JSON without having to bind any volumes.
if [ -n "$VAULT_LOCAL_DATA" ]; then
  echo "$VAULT_LOCAL_DATA" > "$VAULT_DATA_DIR/local-vault-data.json"
fi

# skip if vault data directory is empty
if [ -n "$(find "$VAULT_DATA_DIR" -mindepth 1 -maxdepth 1 -type f 2>/dev/null)" ]; then
  echo "==> loading vault data..."

  for f in "$VAULT_DATA_DIR"/*; do
    case "$f" in
      *.json)
        echo "$0: importing $f"
        jq -rc '.[] | (.key, .secret)' < "$f" | while IFS= read -r key && IFS= read -r secret; do
          echo -n "$secret" | vault kv put $key -
        done
        ;;
      *)
        echo "$0: ignoring $f"
        ;;
    esac
    echo
  done

else
  echo "the directory [$VAULT_DATA_DIR] is empty or non-existent; skipping vault data import"
fi

fg %1
