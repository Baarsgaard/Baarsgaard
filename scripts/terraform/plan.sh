#!/usr/bin/env bash

. ./tf-common.sh $@

echo "Extra args: $EXTRA_ARGS"

# If $RCFG has a value terraform init -reconfigure is skipped.
# on failure it will be unset allowing to run the exact same command once again.
# might get annoying.

#Create plan
terraform $DIR plan $EXTRA_ARGS -out=$BASENAME.plan $VAR || unset RCFG
