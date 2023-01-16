#!/bin/bash

# TODO: PBS comments here


##
## Check args
##

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <project name>.riproject (optional) run_ID" >&2
  echo "Make sure the riproject folder is present either in the VSC_DATA or VSC_SCRATCH directory"
  exit 1
fi


##
## Locate data and copy to scratch for more room and faster executing
## TODO: enable this without being in VO
##

# check if container image present


# get folder name
INPUTFOLDER=$(basename $1)


VO_SCRATCH_DIR="${VSC_SCRATCH_VO}/TLS2trees"
mkdir -p ${VO_SCRATCH_DIR}
#check if in VO SCRATCH, if so no copy needed
if [ ! -d "${VO_SCRATCH_DIR}/$1/" ]; then
    # if not in VO SCRATCH, check if in VO DATA
    echo "Data not found in VO SCRATCH ($VO_SCRATCH_DIR), looking in VO DATA"
    VO_DATA_DIR="${VSC_DATA_VO}/TLS2trees"
    mkdir -p ${VO_DATA_DIR}
    if [ ! -d "${VO_DATA_DIR}/$1" ]; then
        # if not in VO DATA, check if in user DATA
        echo "Data not found in VO DATA ($VO_DATA_DIR), looking in user DATA ($VSC_DATA)"
        if [ ! -d "${VSC_DATA}/$1" ]; then
            # finally check if the argument given is a valid directory, then just copy straight from there
            if [ ! -d "$1" ]; then
                echo "I couldn't find the dataset in either the VO SCRATCH, VO DATA or your personal data folder. Please check the readme to ensure this data is in the correct location, and if the name is spelled correctly."
                exit 1
            else
                echo "Copying to scratch"
                #remove slash if present, so directory is also copied

                rsync -rzvP ${1%/} ${VO_SCRATCH_DIR}
            fi
        else    
            echo "Found in data directory, copying to scratch"
            rsync -rzvP ${VSC_DATA}/$1 ${VO_SCRATCH_DIR}
        fi
    else
        echo "Found in VO data, copying to scratch"
        rsync -rzvP ${VO_DATA_DIR}/$1 ${VO_SCRATCH_DIR}
    fi
else
    echo "Input directory found in scratch, continuing"
    echo "(If any changes were made to the input directory, first delete the directory with the same name in VSC_SCRATCH_VO and restart script)"
fi


# input folder
IDIR="${VO_SCRATCH_DIR}/${INPUTFOLDER}"

# outputfolder with ID if provided
ODIR="${VO_SCRATCH_DIR}/output/$2"
mkdir -p ${ODIR}
# logs in outputfolder
LOGSDIR = "${ODIR}/logs"
mkdir -p ${LOGSDIR}

echo "$(date +[%Y.%m.%d\|%H:%M:%S]) - Starting semantic segmentation"

for FILE in ${IDIR}/extraction/downsample/*.ply ; 
do
  # extract tile name by stripping current file name
  TILE="${FILE##*/}"
  TILE="${TILE%%.*}"
  # run semantic segmentation
  apptainer exec --bind ${IDIR}:/input,${ODIR}:/output ${VO_SCRATCH_DIR}/tls2trees_latest.sif run.py -p /input/extraction/downsample/$TILE.downsample.ply --tile-index /input/extraction/tile_index.dat \
  --verbose --odir /output/SemanticSeg &> ${LOGSDIR}/output$TILE.log &
done

echo "All semantic segmentation containers launched"

# wait for all containers to terminate
wait

echo "$(date +[%Y.%m.%d\|%H:%M:%S]) - Starting instance segmentation"

# TODO: change this for loop to actually loop over created semanticsegmentation files
# TODO: Create array of tiles in previous loop, loop over these and if no file is found, report missing so it can be rerun individually later (or by program)
# TEST TODOS LOCALLY!
for FILE in ${IDIR}/extraction/downsample/*.ply ; 
do
  # extract tile name by stripping current file name
  TILE="${FILE##*/}"
  TILE="${TILE%%.*}"
  # run semantic segmentation
  apptainer exec --bind ${IDIR}:/input,${ODIR}:/output ${VO_SCRATCH_DIR}/tls2trees_latest.sif points2trees.py -t /output/SemanticSeg/$TILE.downsample.segmented.ply \
  --tindex /input/extraction/tile_index.dat --n-tiles 5 --slice-thickness .5 --find-stems-height 2 --find-stems-thickness .5 \
  --add-leaves --add-leaves-voxel-length .5 --graph-maximum-cumulative-gap 3 --save-diameter-class \
  --ignore-missing-tiles --odir /output/clouds/Tile$TILE/ &>> ${LOGSDIR}/output$TILE.log &
done

echo "All instance segmentation containers launched"

# wait for all containers to terminate
wait

# TODO: check here if all files have been created, and maybe create overview of files missing/tiles to rerun


echo "$(date +[%Y.%m.%d\|%H:%M:%S]) - Done"

