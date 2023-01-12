#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 /home/.../XXX.riproject" >&2
  exit 1
fi

echo "Starting semantic segmentation"
mkdir -p logs
for FILE in $1/extraction/downsample/*.ply ; 
do
  # extract tile name by stripping current file name
  TILE="${FILE##*/}"
  TILE="${TILE%%.*}"
  # run semantic segmentation
  singularity exec --bind $1:/data/ tls2trees_latest.sif run.py -p /data/extraction/downsample/$TILE.downsample.ply --tile-index /data/extraction/tile_index.dat \
  --verbose --odir /data/clouds/singularity/SemanticSeg &> ./logs/output$TILE.log &
done

echo "All containers launched, exiting."
