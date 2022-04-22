#!/bin/bash

# TODO: Make this dynamic between products
KOJI_CMD='koji -p stream'
KOJI_TAG='c9s-pending'

# Check for nvr converter and successful inspections
[[ -x ./nvr-to-package.py ]] || exit 1
ls logs/*.success > /dev/null || exit 2

for after_build in $(cat logs/*.success); do
  echo "INFO: Working on ${after_build}"

  # Loop helps with large runs and network issues
  # Not ideal as we could get stuck but so far so good
  while true; do
    # Convert an NVR/Build into a package name
    package=$(./nvr-to-package.py ${after_build})
    if [[ -z "${package}" ]]; then
      echo "$(date) - ERROR: NVR to package check failed on ${after_build} - sleeping"
      sleep 60
      continue
    fi
    echo "$(date) - INFO: Found package ${package}"
    break
  done
  # Find our two latest build for a package in the tag
  builds=$(${KOJI_CMD} list-tagged --latest-n 2 --inherit --quiet ${KOJI_TAG} ${package} | awk '{print $1}' | xargs)
  if [[ -z "$builds" ]]; then
    echo "$(date) - ERROR: package to NVRs logic broke on $package - please investigate."
    exit 1
  fi
  echo "$(date) - INFO: Found $builds"
  # If we find one that's older, that's our comparison
  for before_build in $builds; do
    if [ "${before_build}" != "${after_build}" ]; then
      echo "$(date) - SUCCESS: ${before_build} ${after_build}"
      echo "${before_build} ${after_build}" >> comparison-list.txt
      break
    fi
    echo "$(date) - INFO: ${before_build} and ${after_build} match"
  done

  sleep 0.5

done

# All done
exit 0
