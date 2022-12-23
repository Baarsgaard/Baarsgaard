#!/usr/bin/env bash

. ./tf-common.sh $@

# ${@:3} is applying extra args to the main command

# Create Leftover and configurations
echo "Extra args: $EXTRA_ARGS"
terraform $DIR refresh $EXTRA_ARGS $VAR
terraform $DIR output -json > $BASENAME.json

cd $BASENAME && rm -f $BASENAME.plan
