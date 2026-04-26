#!/usr/bin/env bash
# End-to-end test of lifesupport/scripts/bootstrap.sh inside a container.
#
# Usage:
#   ./run-test.sh           # build + up + run bootstrap + verify
#   ./run-test.sh shell     # exec into the running container
#   ./run-test.sh down      # tear down container + volumes
#   ./run-test.sh logs      # follow container logs
#
# Requires: docker, docker compose, and ~/.ssh/id_ed25519{,.pub} on the host.

set -euo pipefail

cd "$(dirname "$0")"

CONTAINER=lifesupport-dev-test
SSH_PORT=2222
SSH_KEY="$HOME/.ssh/id_ed25519"

# Side-step Docker Desktop's WSL credsStore (which calls a .exe that can't run
# in Linux subprocess context) by using a scoped empty config dir for any docker
# operation this script triggers. Public images need no creds anyway.
export DOCKER_CONFIG="$PWD/.docker-config"
mkdir -p "$DOCKER_CONFIG"
[ -f "$DOCKER_CONFIG/config.json" ] || echo '{}' > "$DOCKER_CONFIG/config.json"

cmd="${1:-test}"

# AUTHORIZED_KEY is required by docker-compose.yml for any compose subcommand
# (even `down`), so set it for the whole script lifetime when the pubkey exists.
if [ -f "$SSH_KEY.pub" ]; then
    export AUTHORIZED_KEY="$(cat "$SSH_KEY.pub")"
fi

up() {
    [ -f "$SSH_KEY" ] || { echo "missing $SSH_KEY — needed for github clone in container"; exit 1; }
    [ -n "${AUTHORIZED_KEY:-}" ] || { echo "missing $SSH_KEY.pub"; exit 1; }
    echo "==> building image"
    docker compose build --quiet
    echo "==> starting container"
    docker compose up -d
    echo "==> waiting for sshd"
    for i in $(seq 1 30); do
        if ssh -p "$SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -o ConnectTimeout=2 -o BatchMode=yes -i "$SSH_KEY" \
            xiao@127.0.0.1 true 2>/dev/null; then
            echo "    sshd ready"
            return 0
        fi
        sleep 1
    done
    echo "sshd did not come up in 30s"
    docker compose logs --tail 50
    exit 1
}

ssh_into() {
    ssh -p "$SSH_PORT" -A \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -i "$SSH_KEY" xiao@127.0.0.1 "$@"
}

run_bootstrap() {
    echo "==> running bootstrap.sh inside container"
    # Pipe the local script in via stdin so we exercise the current working copy
    # (not whatever is in github main). The script clones the repo from github
    # for everything else — that part is still real.
    ssh_into 'bash -s' < ../scripts/bootstrap.sh
}

verify() {
    echo "==> verifying installed tools"
    ssh_into "zsh -i -c '
        set +e
        echo --- versions ---
        nvim --version | head -1
        mise --version
        claude --version 2>&1 | head -1
        echo --- symlinks ---
        ls -la ~/.zshrc ~/.tmux.conf ~/.config/nvim
        echo --- mason packages ---
        ls ~/.local/share/nvim/mason/packages/ 2>/dev/null | tr \"\\n\" \" \"; echo
    '"
}

case "$cmd" in
    up) up ;;
    down) docker compose down -v ;;
    shell) ssh_into ;;
    logs) docker compose logs -f ;;
    bootstrap) run_bootstrap ;;
    verify) verify ;;
    test|"")
        up
        run_bootstrap
        verify
        echo "==> test passed"
        echo "    leave running for inspection, or:  $0 down"
        ;;
    *) echo "unknown command: $cmd"; exit 1 ;;
esac
