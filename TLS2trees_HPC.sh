#!/bin/bash

# TODO: PBS comments here

# swap to kirlia cluster
module swap cluster/kirlia



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

# check if user part of VO
if [ -z "${VSC_SCRATCH_VO}" ]; then
    echo "We detect that the VSC_SCRATCH_VO variable is not set, currently this script only works if you are part of a VO"
    echo "Please contact me if you want to join the CAVElab VO"
    echo "$(date +[%Y.%m.%d\|%H:%M:%S]) - Exiting"
    exit 1
fi



VO_SCRATCH_DIR="${VSC_SCRATCH_VO}/TLS2trees"
mkdir -p ${VO_SCRATCH_DIR}

# check if container image present
if [ -f "${VO_SCRATCH_DIR}/tls2trees_latest.sif" ]; then
    echo "Couldn't find the tls2trees_latest.sif file in ${VO_SCRATCH_DIR}, please refer to the manual to ensure it is there."
    echo "$(date +[%Y.%m.%d\|%H:%M:%S]) - Exiting"
    exit 1
fi


# get folder name
INPUTFOLDER=$(basename $1)

#check if in VO SCRATCH, if so no copy needed
if [ ! -d "${VO_SCRATCH_DIR}/${INPUTFOLDER}/" ]; then
    # if not in VO SCRATCH, check if in VO DATA
    echo "Data not found in VO SCRATCH ($VO_SCRATCH_DIR), looking in VO DATA"
    VO_DATA_DIR="${VSC_DATA_VO}/TLS2trees"
    mkdir -p ${VO_DATA_DIR}
    if [ ! -d "${VO_DATA_DIR}/${INPUTFOLDER}" ]; then
        # if not in VO DATA, check if in user DATA
        echo "Data not found in VO DATA ($VO_DATA_DIR), looking in user DATA ($VSC_DATA)"
        if [ ! -d "${VSC_DATA}/${INPUTFOLDER}" ]; then
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


##
## Run semantic segmentation
##

# input folder
IDIR="${VO_SCRATCH_DIR}/${INPUTFOLDER}"

# outputfolder with ID if provided
ODIR="${VO_SCRATCH_DIR}/output/$2"
mkdir -p ${ODIR}

# logs in outputfolder
LOGSDIR = "${ODIR}/logs"
mkdir -p ${LOGSDIR}

# SIF location
SIF_LOC = "${VO_SCRATCH_DIR}/tls2trees_latest.sif"

echo "$(date +[%Y.%m.%d\|%H:%M:%S]) - Starting semantic segmentation"

SEM_TILES=()
for FILE in ${IDIR}/extraction/downsample/*.ply ; 
do
  # extract tile name by stripping current file name
  TILE="${FILE##*/}"
  TILE="${TILE%%.*}"
  SEM_TILES+=( $TILE )
  # run semantic segmentation
  apptainer exec --bind ${IDIR}:/input,${ODIR}:/output ${SIF_LOC} run.py -p /input/extraction/downsample/$TILE.downsample.ply --tile-index /input/extraction/tile_index.dat \
  --verbose --odir /output/SemanticSeg &> ${LOGSDIR}/output$TILE.log &
done

echo "All semantic segmentation containers launched"

# wait for all containers to terminate
wait

##
## Run instance segmentation
##

echo "$(date +[%Y.%m.%d\|%H:%M:%S]) - Starting instance segmentation"


SEMSEG_OUT="${ODIR}/SemanticSeg"

INST_TILES=()
for FILE in ${SEMSEG_OUT}/*.ply ; 
do
  # extract tile name by stripping current file name
  TILE="${FILE##*/}"
  TILE="${TILE%%.*}"
  INST_TILES+=( $TILE )
  # run semantic segmentation
  apptainer exec --bind ${IDIR}:/input,${ODIR}:/output ${SIF_LOC} points2trees.py -t /output/SemanticSeg/$TILE.downsample.segmented.ply \
  --tindex /input/extraction/tile_index.dat --n-tiles 5 --slice-thickness .5 --find-stems-height 2 --find-stems-thickness .5 \
  --add-leaves --add-leaves-voxel-length .5 --graph-maximum-cumulative-gap 3 --save-diameter-class \
  --ignore-missing-tiles --odir /output/clouds/Tile$TILE/ &>> ${LOGSDIR}/output$TILE.log &
done

echo "All instance segmentation containers launched"

# wait for all containers to terminate
wait

echo "$(date +[%Y.%m.%d\|%H:%M:%S]) - Instance segmentation finished"


##
## Give overview of which tiles have succeeded
##

# detect failed semantic segmentation by comparing launched semantic vs instance seg containers

SEMSEG_SUCCES=()
SEMSEG_FAIL=()
for i in "${SEM_TILES[@]}" ;
do
    FOUND=false
    for j in "${INST_TILES[@]}" ;
    do
        if [ "$i" -eq "$j" ] ; then
            FOUND=true
            break
        fi
    done
    if [ "$FOUND" = true ] ; then
        SEMSEG_SUCCES+=( $i )
    else
        SEMSEG_FAIL+=( $i )
    fi
done

# detect failed instance segmentation by comparing launched instance seg containers and output

FULL_SUCCES=() 
# check directories to see which tiles have been completed
for dir in ${IDIR}/clouds/*/ ;
do
    DIR=$(basename $dir)
    if [ ${DIR::4} == "Tile" ] ; then
        FULL_SUCCES+=( ${DIR:4} )
    fi
done
echo ${FULL_SUCCES[@]}

INSTSEG_SUCCES=()
INSTSEG_FAIL=()
# detect tiles not in INST_ARRAY
for i in "${INST_TILES[@]}" ;
do
    FOUND=false
    for j in "${SUCCES[@]}" ;
    do
        if [ "$i" -eq "$j" ] ; then
            FOUND=true
            break
        fi
    done
    if [ "$FOUND" = true ] ; then
        INSTSEG_SUCCES+=( $i )
    else
        INSTSEG_FAIL+=( $i )
    fi
done

# print summary

echo "Printing summary of succeeded tiles."
echo "Failed semantic segmentation containers (Total: ${#SEMSEG_FAIL[@]}/${#SEM_TILES[@]})"
for FAILED in "${SEMSEG_FAIL[@]}";
do
    echo "$FAILED"
done
echo "Failed instance segmentation containers (Total: ${#INSTSEG_FAIL[@]}/${#INST_TILES[@]})"
for FAILED in "${INSTSEG_FAIL[@]}";
do
    echo "$FAILED"
done

echo "$(date +[%Y.%m.%d\|%H:%M:%S]) - Done"

