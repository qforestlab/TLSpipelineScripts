#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 /home/.../XXX.riproject" >&2
  exit 1
fi

echo "$(date +[%Y.%m.%d\|%H:%M:%S]) - Starting semantic segmentation"

mkdir -p logs
for FILE in $1/extraction/downsample/*.ply ; 
do
  # extract tile name by stripping current file name
  TILE="${FILE##*/}"
  TILE="${TILE%%.*}"
  # run semantic segmentation
  singularity exec --bind $1:/data/ tls2trees_latest.sif run.py -p /data/extraction/downsample/$TILE.downsample.ply --tile-index /data/extraction/tile_index.dat --buffer 2 \
  --verbose --odir /data/clouds/singularity/SemanticSeg &> ./logs/output$TILE.log &
done

# wait for containers to be done
wait

echo "$(date +[%Y.%m.%d\|%H:%M:%S]) - Starting instance segmentation"

for FILE in $1/extraction/downsample/*.ply ; 
do
  # extract tile name by stripping current file name
  TILE="${FILE##*/}"
  TILE="${TILE%%.*}"
  # run semantic segmentation
  singularity exec --bind $1:/data/ tls2trees_latest.sif points2trees.py -t /data/clouds/singularity/SemanticSeg/$TILE.downsample.segmented.ply \
  --tindex /data/extraction/tile_index.dat --n-tiles 5 --slice-thickness .2 --find-stems-height 1.3 --find-stems-thickness .1 --find-stems-min-radius 0.05 \
  --add-leaves --add-leaves-voxel-length .5 --graph-maximum-cumulative-gap 3 --save-diameter-class --verbose \
  --ignore-missing-tiles --odir /data/clouds/singularity/Tile$TILE/Trees &>> ./logs/output$TILE.log &
done


# wait for containers to be done
wait

echo "$(date +[%Y.%m.%d\|%H:%M:%S]) - Done - exiting"

# set output to be owned by user who ran script
chown -R ${SUDO_USER:-${USER}}:${SUDO_USER:-${USER}} $1
#chown -R $(logname):$(logname) $1