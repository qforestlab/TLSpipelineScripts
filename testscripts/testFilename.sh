#!/bin/bash


if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <project name>.riproject (optional) run_ID" >&2
  echo "Make sure the riproject folder is present either in the VSC_DATA or VSC_SCRATCH directory"
  exit 1
fi

ODIR="${PWD}/output/$2/logs"
mkdir -p $ODIR
echo $ODIR
