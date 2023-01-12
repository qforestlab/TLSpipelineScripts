#!/bin/bash

# TODO: PBS comments here

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 /home/.../XXX.riproject" >&2
  exit 1
fi

# TODO: copy data to SCRATCH first
# TODO: change to correct file locations using $VSC_SCRATCH etc.
# TODO: set odir as variable

echo "$(date +[%Y.%m.%d\|%H:%M:%S]) - Starting semantic segmentation"
mkdir -p logs


for FILE in $1/extraction/downsample/*.ply ; 
do
  # extract tile name by stripping current file name
  TILE="${FILE##*/}"
  TILE="${TILE%%.*}"
  # run semantic segmentation
  apptainer exec --bind $1:/data/ tls2trees_latest.sif run.py -p /data/extraction/downsample/$TILE.downsample.ply --tile-index /data/extraction/tile_index.dat \
  --verbose --odir /data/clouds/singularity/SemanticSeg &> ./logs/output$TILE.log &
done

echo "All semantic segmentation containers launched"

# wait for all containers to terminate
wait

echo "$(date +[%Y.%m.%d\|%H:%M:%S]) - Starting instance segmentation"

# TODO: change this for loop to actually loop over created semanticsegmentation files
# TODO: Create array of tiles in previous loop, loop over these and if no file is found, report missing so it can be rerun individually later (or by program)
for FILE in $1/extraction/downsample/*.ply ; 
do
  # extract tile name by stripping current file name
  TILE="${FILE##*/}"
  TILE="${TILE%%.*}"
  # run semantic segmentation
  apptainer exec --bind $1:/data/ tls2trees_latest.sif points2trees.py -t /data/clouds/singularity/SemanticSeg/$TILE.downsample.segmented.ply \
  --tindex /data/extraction/tile_index.dat --n-tiles 5 --slice-thickness .5 --find-stems-height 2 --find-stems-thickness .5 \
  --add-leaves --add-leaves-voxel-length .5 --graph-maximum-cumulative-gap 3 --save-diameter-class \
  --ignore-missing-tiles --odir /data/clouds/singularity/Tile$TILE/Trees &>> ./logs/output$TILE.log &
done

echo "All instance segmentation containers launched"

# wait for all containers to terminate
wait

# TODO: check here if all files have been created, and maybe create overview of files missing/tiles to rerun


echo "$(date +[%Y.%m.%d\|%H:%M:%S]) - Done"

