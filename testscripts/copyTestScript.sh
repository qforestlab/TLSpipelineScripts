#!/bin/bash

##
## Locate data and copy to scratch for more room and faster executing
##

# get folder name
INPUTFOLDER=$(basename $1)

# TODO: enable this without being in VO

VO_SCRATCH_DIR="${VSC_SCRATCH_VO}/TLS2trees"
mkdir -p ${VO_SCRATCH_DIR}
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


IDIR="${VO_SCRATCH_DIR}/${INPUTFOLDER}"