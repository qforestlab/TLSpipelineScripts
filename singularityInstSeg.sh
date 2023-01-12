#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 /home/.../XXX.riproject" >&2
  exit 1
fi

echo "Starting instance segmentation"
mkdir -p logs
for FILE in $1/extraction/downsample/*.ply ; 
do
  # extract tile name by stripping current file name
  TILE="${FILE##*/}"
  TILE="${TILE%%.*}"
  # run semantic segmentation
  singularity exec --bind $1:/data/ tls2trees_latest.sif points2trees.py -t /data/clouds/singularity/SemanticSeg/$TILE.downsample.segmented.ply \
  --tindex /data/extraction/tile_index.dat --n-tiles 5 --slice-thickness .5 --find-stems-height 2 --find-stems-thickness .5 \
  --add-leaves --add-leaves-voxel-length .5 --graph-maximum-cumulative-gap 3 --save-diameter-class \
  --ignore-missing-tiles --odir /data/clouds/singularity/Tile$TILE/Trees &>> ./logs/output$TILE.log &
done

echo "All containers launched, exiting."