#!/usr/bin/env bash

set -e

[ -z "$ARM_ACCESS_KEY" ] && \
echo '  Error: ARM_ACCESS_KEY is unset' && \
echo '  Get key from: https://pwdb/pid=13420' && \
echo '  export ARM_ACCESS_KEY=<key>' && \
echo '' && exit 1

[ -z "$1" ] && echo '  Missing arg, project (dir)' && exit 1
[ -z "$2" ] && echo '  Missing arg, vars file (*.tfvars)' && exit 1

[ ! -z "$1" ] && DIR="-chdir=$(readlink -f $1)"
[ ! -z "$2" ] && VAR="-var-file=$(readlink -f $2)"


BASENAME="$(basename $(readlink -f $1))"
EXTRA_ARGS="${@:3}"

# Ensure backend
if [ -z "${RCFG+x}" ]; then
  terraform $DIR init -reconfigure
fi

set -v
