#!/bin/bash

set -xe

if [ $# != 2 ]; then
  echo "Usage: $(basename $0) SUFFIX NUM"
  echo
  echo "Will deploy four apps, scale them to 15 instances total, and repeat NUM times"
  exit 2
fi

suffix=$1
numtimes=$2

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

for i in `seq $numtimes`; do

  echo "Pushing apps..."

  cf push westley-$suffix -p assets/apps/westley -m 128M  &> $suffix.out
  cf push max-$suffix -p assets/apps/max -m 512M &> $suffix.out
  cf push buttercup-$suffix -p assets/apps/princess -m 1024M  &> $suffix.out
  cf push humperdink-$suffix -p assets/apps/humperdink -m 128M  &> $suffix.out

  scale_up_start_time=$(date +%s)

  for i in `seq 20` ; do
    echo "Scaling apps, round $i..."

    cf scale humperdink-$suffix -i $(( 2*$i )) &> $suffix.out
    cf scale westley-$suffix -i $(( 8*$i )) &> $suffix.out
    cf scale max-$suffix -i $(( 4*$i )) &> $suffix.out
    cf scale buttercup-$suffix -i $(( 1*$i )) &> $suffix.out

    check_state westley-$suffix $(( 8*$i ))
    check_state max-$suffix $(( 4*$i ))
    check_state buttercup-$suffix $(( 1*$i ))
  done

  scale_up_end_time=$(date +%s)

  echo "Sleeping for 1 minute..."
  sleep 60

  scale_down_start_time=$(date +%s)

  echo "Deleting the apps..."
  cf d -f humperdink-$suffix &> $suffix.out
  cf d -f westley-$suffix &> $suffix.out
  cf d -f max-$suffix &> $suffix.out
  cf d -f buttercup-$suffix &> $suffix.out

  scale_down_end_time=$(date +%s)

  echo "$scale_up_start_time,$scale_up_end_time,$scale_down_start_time,$scale_down_end_time" >> results.csv

  echo "Sleeping for 30 seconds..."
  sleep 30
done

