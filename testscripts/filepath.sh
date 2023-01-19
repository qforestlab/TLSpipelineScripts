#!/bin/bash


IDIR="/home/wcherlet/data/UK015A.riproject"

for FILE in $IDIR/extraction/downsample/*.ply ; 
do
  echo "DEBUG: printing FILE variable: ${FILE}"
done

for FILE in ~/data/UK015A.riproject/extraction/downsample/*.ply ;
do
  echo "DEBUG: printing FILE variable: ${FILE}"
done