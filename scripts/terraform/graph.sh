#!/usr/bin/env bash

. ./tf-common.sh $1 $2

#Create plan
terraform $DIR graph -type=refresh | dot -x -Tsvg > $BASENAME.svg

#cd $1 && rm -f $DIR.plan
