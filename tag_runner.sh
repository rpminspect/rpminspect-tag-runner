#!/bin/bash
# List of builds to break into threads
if [[ $1 == '--help' ]]; then 
  echo "$(basename $0) - manages multiple rpminspect runs in parallel from a given list."
  echo
  echo "USAGE: $(basename $0) [list.txt] [threads]"
  exit 1
fi

# Make sure rpminspect is in out PATH
which rpminspect > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "ERROR: Cannot find rpminspect in PATH." >&2
  exit 1
fi

# Make sure list exists, either as default list.txt
# or as a user-defined list file
list='list.txt'
[[ -n ${1} ]] && list="${1}"
if [[ ! -e "${list}" ]]; then
  echo "ERROR: Cannot find list file ${list}" >&2
  exit 1
fi

# How many threads does the system have available to use
threads=$(grep -c processor /proc/cpuinfo)
if [[ -z "${threads}" ]]; then
  echo "ERROR: Unable to find number of system threads." >&2
  exit 1
fi

# User has requested a number of threads
if [[ -n "$2" ]]; then

# Input validation - wrapping vars in quotes breaks it. Thanks bash.
# https://stackoverflow.com/questions/806906/how-do-i-test-if-a-variable-is-a-number-in-bash
  re='^[0-9]+$'
  if ! [[ $2 =~ ${re} ]]; then
    echo "ERROR: Thread value ${2} is not a number." >&2
    exit 1
  fi

  # Minimum of 2 threads
  if [[ ${2} -lt 2 ]]; then
    echo "INFO: Requested $2 threads but using 2 (minimum) threads instead"
    threads=2
  # If user requests less threads than max but more than 1
  elif [[ ${2} -lt ${threads} ]]; then
    threads="$2"
  else
    echo "INFO: Requested $2 threads but using $threads (max) threads instead."
  fi

fi

# Freshen up them clams
echo "Updating ClamAV"
sudo freshclam

# One job per thread as requested
cat ${list} | while read line; do

  # If all slots taken, wait a bit
  while [[ $(jobs -p | wc -l) -ge ${threads} ]]; do
    echo "$(date) - $(jobs -p | wc -l) rpminspect jobs currently running:"
    ps x | grep '[r]un_rpminspect.sh'
    sleep 5
  done

  # Start a thread up when available with a tiny pause to stagger initial startup
  echo "$(date) - Testing ${line}" | tee -a run.log
  ./run_rpminspect.sh $line &
  sleep 0.5

done

# Don't forget the hanging chads
while [[ $(pgrep -c rpminspect) -gt 0 ]]; do
  echo "$(date) - Waiting for our final jobs to finish"
  ps x | grep '[r]un_rpminspect.sh'
  sleep 5
done

# All done
echo "$(date) - Run completed."
exit 0
