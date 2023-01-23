#!/bin/bash

# runs the TLS pipeline on all tiles in parallel

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 /home/.../XXX.riproject" >&2
  exit 1
fi

echo "$(date +[%Y.%m.%d\|%H:%M:%S]) - Launching semantic segmentation containers"

# RUN SEMANTIC SEGMENTATION IN PARALLEL ON ALL TILES
CONTAINER_LIST=""
for FILE in $1/extraction/downsample/*.ply ; 
do
  # extract tile name by stripping current file name
  TILE="${FILE##*/}"
  TILE="${TILE%%.*}"
  # build container name
  CONT_NAME="SEMSEG${TILE}"
  # run semantic segmentation, detached mode for parallelization
  docker run -d --rm -v $1:/data/ --name $CONT_NAME tls2trees:latest run.py -p /data/extraction/downsample/$TILE.downsample.ply --tile-index /data/extraction/tile_index.dat \
  --verbose --buffer 2 --odir /data/clouds/SemanticSeg
  CONTAINER_LIST+="$CONT_NAME "
done

echo "$(date +[%Y.%m.%d\|%H:%M:%S]) - All semantic segmentation containers started, waiting for output"

# wait for all segmantic segmentation containers to have ended
docker wait $CONTAINER_LIST

echo "$(date +[%Y.%m.%d\|%H:%M:%S]) - Launching instance segmentation containers"

# RUN INSTANCE SEGMENTATION ON ALL TILES IN PARALLEL
CONTAINER_LIST2=""

# TODO: this loop shouldn't loop over the extraction folder but over the SemanticSeg folder
for FILE in $1/extraction/downsample/*.ply ;
do
  # extract tile name by stripping current file name
  TILE="${FILE##*/}"
  TILE="${TILE%%.*}"
  # build container name
  CONT_NAME="INSTSEG${TILE}"
  # run instance segmentation for individual trees
  docker run -d --rm -v $1:/data/ --name $CONT_NAME tls2trees:latest points2trees.py -t /data/clouds/SemanticSeg/$TILE.downsample.segmented.ply \
  --tindex /data/extraction/tile_index.dat --n-tiles 5 --slice-thickness .2 --find-stems-height 1.3 --find-stems-thickness .6 --find-stems-min-radius 0.05 \
  --find-stems-min-points 200 --add-leaves --add-leaves-voxel-length .5 --add-leaves-edge-length 1 --graph-edge-length 2 --graph-maximum-cumulative-gap 3 --save-diameter-class --verbose \
  --ignore-missing-tiles --min-points-per-tree 200 --odir /data/clouds/Tile$TILE/Trees
  CONTAINER_LIST2+="$CONT_NAME "
done

echo "$(date +[%Y.%m.%d\|%H:%M:%S]) - All instance segmentation containers started"

# wait for all instance segmentation containers to have ended\
docker wait $CONTAINER_LIST2

echo "$(date +[%Y.%m.%d\|%H:%M:%S]) - Done, setting output to be owned by user who ran script"

# set output to be owned by user who ran script
chown -R ${SUDO_USER:-${USER}}:${SUDO_USER:-${USER}} $1
#chown -R $(logname):$(logname) $1
