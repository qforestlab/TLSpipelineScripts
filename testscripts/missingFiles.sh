#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 /home/.../XXX.riproject" >&2
  exit 1
fi

SEM_TILES=()
for FILE in ${1}/extraction/downsample/*.ply ; 
do
  # extract tile name by stripping current file name
  TILE="${FILE##*/}"
  TILE="${TILE%%.*}"
  SEM_TILES+=( $TILE )
done
echo ${SEM_TILES[@]}

SEMSEG_OUT="$1/clouds/SemanticSeg"

INST_TILES=()
for FILE in ${SEMSEG_OUT}/*.ply ;
do
  TILE="${FILE##*/}"
  TILE="${TILE%%.*}"
  INST_TILES+=( $TILE )
done

echo ${INST_TILES[@]}


SEMSEG_SUCCES=()
SEMSEG_FAIL=()
# detect tiles not in INST_ARRAY
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

echo ${SEMSEG_SUCCES[@]}
echo ${SEMSEG_FAIL[@]}

FULL_SUCCES=() 

# check TILES to see if INST SEG failed
for dir in $1/clouds/*/ ;
do
    DIR=$(basename $dir)
    if [ ${DIR::4} == "Tile" ] ; then
        SUCCES+=( ${DIR:4} )
    fi
done
echo ${SUCCES[@]}


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

echo ${INSTSEG_SUCCES[@]}
echo ${INSTSEG_FAIL[@]}



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
