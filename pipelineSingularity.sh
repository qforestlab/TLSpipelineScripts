#!/bin/bash
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 /home/.../XXX.riproject TileID" >&2
  exit 1
fi

echo "$(date +[%Y.%m.%d\|%H:%M:%S]) - Starting semantic segmentation"

mkdir -p logs

#run semantic segmentation
singularity exec --bind $1:/data/ tls2trees_latest.sif run.py -p /data/extraction/downsample/$2.downsample.ply --tile-index /data/extraction/tile_index.dat --buffer 2 \
  --verbose --odir /data/clouds/singularity/SemanticSeg &> ./logs/output$2.log &

#wait for semantic segmentation to finish
BACK_PID=$!

echo "$(date +[%Y.%m.%d\|%H:%M:%S]) - Semantic segmentation started"

wait $BACK_PID

echo "$(date +[%Y.%m.%d\|%H:%M:%S]) - Starting instance segmentation"

#run instance segmentation for individual trees
singularity exec --bind $1:/data/ tls2trees_latest.sif points2trees.py -t /data/clouds/singularity/SemanticSeg/$2.downsample.segmented.ply \
--tindex /data/extraction/tile_index.dat --n-tiles 5 --slice-thickness .2 --find-stems-height 1.3 --find-stems-thickness .1 --find-stems-min-radius 0.05 \
--add-leaves --add-leaves-voxel-length .5 --graph-maximum-cumulative-gap 3 --save-diameter-class --verbose \
--ignore-missing-tiles --odir /data/clouds/singularity/Tile$2/Trees &>> ./logs/output$2.log &


# wait for started process
BACK_PID=$!
echo "$(date +[%Y.%m.%d\|%H:%M:%S]) - Instance segmentation started"

wait $BACK_PID

echo "$(date +[%Y.%m.%d\|%H:%M:%S]) - Finished"

#set output to be owned by user who ran script
chown -R ${SUDO_USER:-${USER}}:${SUDO_USER:-${USER}} $1
#chown -R $(logname):$(logname) $0