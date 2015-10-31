#!/bin/bash

check_state() {
  name=$1
  instances=$2

  while true; do
    if [[ $(cf app $name | grep "#" | egrep -v "(starting|stopped)" | wc -l) -eq $instances ]]; then
      return
    fi
  done;
}

test_stage() {
  ( cf push max -p assets/apps/max -m 512M >> max1.log ) &
  ( cf push max2 -p assets/apps/max -m 512M >> max2.log ) &
  ( cf push max3 -p assets/apps/max -m 512M >> max3.log ) &
  ( cf push max4 -p assets/apps/max -m 512M >> max4.log ) &
  check_state max 1
  check_state max2 1
  check_state max3 1
  check_state max4 1
  sleep 2
  cf d -f max
  cf d -f max2
  cf d -f max3
  cf d -f max4
}

set -e -x

export CF_HOME=/tmp/diego-2

cf api api.diego-2.cf-app.com --skip-ssl-validation
cf auth admin sk1N875job

cf create-org jim
cf create-space jim -o jim
cf t -o jim -s jim

cf create-quota jim -m 100000GB -r 10000
cf set-quota jim jim

cf push humperdink -p assets/apps/humperdink -m 128M -i 3
cf push westley -p assets/apps/westley -m 128M

for i in `seq 12`; do
  cf scale westley -i $(( 5*$i ))
  check_state westley $(( 5*$i ))
done

while true; do
  test_stage
done
