#!/bin/bash

# check arguments
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <container name>" >&2
  exit 1
fi

# check if container exists
if [ ! "$(docker ps -a | grep $1)" ]; then
    echo "Container not found, please check if name $1 is correct"
    exit 1
fi

if [ -t 0 ]; then
  SAVED_STTY="`stty --save`"
  stty -echo -icanon -icrnl time 0 min 0
fi

# variables
count=0
keypress=''
peakMem=0
peakCPU=0
peakMemU=0
meanMem=0
meanCPU=0
meanMemU=0
curMem=0
curCPU=0
curMemU=0
prevMemU=0

# create log file
mkdir -p logs
rm -f logs/statscontainer_$1.log
touch logs/statscontainer_$1.log

echo "Starting loop, press any key to stop"
while [ "x$keypress" = "x" ]; do
  # loop every second
  sleep 1

  # get stats
  if [ "$( docker container inspect -f '{{.State.Status}}' $1 )" == "running" ]; then
    stats=$(docker stats --no-stream --format "{{ json . }}" $1)
    curMem=$( echo "$stats" | jq .MemPerc)
    curCPU=$( echo "$stats" | jq .CPUPerc)
    curMemU=$( echo "$stats" | jq .MemUsage)
  else
    # if container not running, break while loop
    echo "container not found running, quitting"
    break
  fi

  # get peak and mean mem perc
  tmp=${curMem#*\"}
  curMem=${tmp%\%*}
  if [ $(bc <<< "$curMem > $peakMem") -gt 0 ]; then
    peakMem=$curMem
    #echo "new peak mem: $curMem"
  fi

  # get peak and mean mem usage
  tmp=${curMemU#*\"}
  curMemU=${tmp%%G*}
  curMemUMB=${curMemU%%M*} # in case of Mib memory (should probably also check for Kib)
  if [[ ${#curMemU} != ${#curMemUMB} ]]; then
    curMemU=$(bc -l <<< "$curMemUMB/1000")
  fi
  if [ $(bc <<< "$curMemU > $peakMemU") -gt 0 ]; then
    peakMemU=$curMemU
    #echo "new peak mem usage: $curMemU"
  fi

  # also update log file with time and number of iterations if mem usage changed
  if [ "$curMemU" != "$prevMemu" ]; then
    # write time and iteration
    echo  "$(date +[%Y.%m.%d\|%H:%M:%S]) - iteration ${count}" >> logs/statscontainer_$1.log
    # also write full stats to log file
    docker stats --no-stream $1 >> logs/statscontainer_$1.log
    prevMemU=$curMemU
  fi

  # get peak and mean cpu perc
  tmp=${curCPU#*\"}
  curCPU=${tmp%\%*}
  if [ $(bc <<< "$curCPU > $peakCPU") -gt 0 ]; then
    peakCPU=$curCPU
    #echo "new peak cpu: $curCPU"
  fi

  #update means (sum up)
  meanMem=$(bc<<<"$meanMem + $curMem")
  meanCPU=$(bc<<<"$meanCPU + $curCPU")
  meanMemU=$(bc<<<"$meanMemU + $curMemU")

  let count+=1
  keypress="`cat -v`"
done


# print out stats and log after keypress
echo "STATS:" | tee -a logs/statscontainer_$1.log
echo "Mean memory percentage: $(bc -l <<< "$meanMem/$count") %" | tee -a logs/statscontainer_$1.log
echo "Peak memory percentage: $peakMem %" | tee -a logs/statscontainer_$1.log
echo "Mean memory usage: $(bc -l <<< "$meanMemU/$count") GiB" | tee -a logs/statscontainer_$1.log
echo "Peak memory usage: $peakMemU GiB" | tee -a logs/statscontainer_$1.log
echo "Mean CPU percentage: $(bc -l <<< "$meanCPU/$count") %" | tee -a logs/statscontainer_$1.log
echo "Peak CPU percentage: $peakCPU %" | tee -a logs/statscontainer_$1.log
echo "Full log file with time more stats can be found at logs/statscontainer_$1.log"

if [ -t 0 ]; then stty "$SAVED_STTY"; fi

exit 0