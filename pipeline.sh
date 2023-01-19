#!/bin/bash
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 /home/.../XXX.riproject TileID" >&2
  exit 1
fi
#run semantic segmentation
docker run -d --rm -v $1:/data/ --name=semseg$2 tls2trees:latest run.py -p /data/extraction/downsample/$2.downsample.ply \
--tile-index /data/extraction/tile_index.dat --verbose --buffer 1 --odir /data/clouds/SemanticSeg
#wait for semantic segmentation to finish
echo "semantic segmentation started, name=semseg$2"
# TODO: TEMP: start up monitoring of docker container to view MEM and CPU usage
./logContainerStats.sh semseg$2
#wait for instance segmentation to finish
docker wait semseg$2
echo "starting instance segmentation"
#run instance segmentation for individual trees
docker run -d --rm -v $1:/data/ --name=instseg$2 tls2trees:latest points2trees.py -t /data/clouds/SemanticSeg/$2.downsample.segmented.ply \
--tindex /data/extraction/tile_index.dat --n-tiles 5 --slice-thickness .5 --find-stems-height 2 --find-stems-thickness .5 \
--verbose --add-leaves --add-leaves-voxel-length .5 --graph-maximum-cumulative-gap 3 --save-diameter-class \
--ignore-missing-tiles --odir /data/clouds/Tile$2/Trees
echo "instance segmentation started, name=instseg$2"
# TODO: TEMP: start up monitoring of docker container to view MEM and CPU usage
./logContainerStats.sh instseg$2
#wait for instance segmentation to finish
docker wait instseg$2
#set output to be owned by user who ran script
chown -R ${SUDO_USER:-${USER}}:${SUDO_USER:-${USER}} $1
#chown -R $(logname):$(logname) $0