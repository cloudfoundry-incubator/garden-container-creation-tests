#!/bin/bash

set -xe

exec > $1.out
exec 2>&1

suffix=$1

check_state() {
  name=$1
  instances=$2

  while true; do
    if [[ $(cf app $name | grep "#" | egrep -v "(starting|stopped)" | wc -l) -eq $instances ]]; then
      return
    fi
  done;
}

touch results.csv

while true; do

  cf push westley-$suffix -p assets/apps/westley -m 128M 
  cf push max-$suffix -p assets/apps/max -m 512M
  cf push buttercup-$suffix -p assets/apps/princess -m 1024M 
  cf push humperdink-$suffix -p assets/apps/humperdink -m 128M 

  scale_up_start_time=$(date +%s)

  for i in `seq 20` ; do
    cf scale humperdink-$suffix -i $(( 2*$i ))
    cf scale westley-$suffix -i $(( 8*$i ))
    cf scale max-$suffix -i $(( 4*$i ))
    cf scale buttercup-$suffix -i $(( 1*$i ))

    check_state westley-$suffix $(( 8*$i ))
    check_state max-$suffix $(( 4*$i ))
    check_state buttercup-$suffix $(( 1*$i ))
  done

  scale_up_end_time=$(date +%s)

  sleep 60

  scale_down_start_time=$(date +%s)

  cf d -f humperdink-$suffix
  cf d -f westley-$suffix
  cf d -f max-$suffix
  cf d -f buttercup-$suffix

  scale_down_end_time=$(date +%s)

  echo "$scale_up_start_time,$scale_up_end_time,$scale_down_start_time,$scale_down_end_time" >> results.csv

  sleep 30
done

