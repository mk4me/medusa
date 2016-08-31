#!/bin/bash

DATA_INPUT="./input"
DATA_OUTPUT="./_output"

echo MyModule start v1.0
echo "Parameters:[$1]"
echo Cleaning temporary files $DATA_OUTPUT
rm -Rf $DATA_OUTPUT
mkdir -p $DATA_OUTPUT

python merge_synovitis.py "DataInputDir=$DATA_INPUT;DataOutputDir=$DATA_OUTPUT;$1"

echo Done.



