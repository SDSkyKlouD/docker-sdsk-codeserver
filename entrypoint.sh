#!/usr/bin/env bash
set -eu

echo "=== SDSK code-server ENTRYPOINT ==="
echo "  \$CODE_DATA = $CODE_DATA"
echo "  \$PATH = $PATH"
echo "  Current user  = $(id -un)"
echo "  Current group = $(id -gn)"
echo "  Entrypoint arguments = ${@}"
echo

export USER="$(whoami)"
dumb-init fixuid -q /usr/bin/code-server $(echo "${@}" | sed -e "s|{0}|$CODE_DATA|g" | sed -e "s|{1}|$CODE_EXTENSIONS|g")