#!/bin/bash
# tag_runner.sh
# This script does the bulk of the work, breaking a list of NVRs to run across
# several threads to speed up testing across an entire tag of packages.

# Usage since we have a few options we can handle
usage() {
  echo "$(basename $0) - manages multiple rpminspect runs in parallel from a given list."
  echo
  echo "Usage: $(basename $0) [-h] [-f <file with nvrs>] [-t <number of threads>] [-p <profile>]" 1>&2
}

# Check for user specified options
while getopts ":f:ht:p:" arg; do
  case "${arg}" in
    f)
      list="${OPTARG}"
      ;;
    t)
      threads="${OPTARG}"
      ;;
    p)
      profile="${OPTARG}"
      ;;
    h)
      usage && exit 0
      ;;
    *)
      usage && exit 1
      ;;
  esac
done

shift "$(($OPTIND - 1))"

# TODO: Make getopts handle this.
# I just want to keep moving forward on the refactoring for now.
if [[ $# -ne 0 ]]; then
    echo "ERROR: $# unexpected options still left. Exiting." >&2
    echo "Extra arguments: $@" >&2
    echo
    usage
    exit 1
fi

# Default values if none provided by user
[[ -z "${threads}" ]] && threads=0
[[ -z "${profile}" ]] && profile="c9s"

# Try to import instead of looking for the file
source profiles/${profile}.sh
if [[ $? -ne 0 ]]; then
  echo "ERROR: Unable to load profile ${profile}" >&2
  exit 1
# Validate all required vars are present
elif [[ -z "${KOJI_CMD}" ]] || \
     [[ -z "${KOJI_TAG}" ]] || \
     [[ -z "${KOJI_URL}" ]] || \
     [[ -z "${RPMINSPECT_CMD}" ]]; then
  echo "ERROR: profile ${profile} is missing required KOJI value(s)." >&2
  exit 1
fi

# Define the default and generate our list if missing
if [[ -z "${list}" ]]; then 
  list="list.txt"
  comp_list='comparison-list.txt'
  auto_run_comp='false'
  # If no args or default files, setup for a re-run at the end
  [[ -e ${list} ]] || ./generate-list.sh -p ${profile}
  [[ -e ${comp_list} ]] || auto_run_comp='true'
fi 

# Validations against our inputs
re='^[0-9]+$'
if ! [[ -e "${list}" ]]; then
  echo "ERROR: List file ${list} is missing" >&2
  usage
  exit 1
elif ! [[ $threads =~ ${re} ]]; then
  echo "ERROR: Threads should be a numeric value." >&2
  usage
  exit 1
fi

# Make sure rpminspect is present
which rpminspect > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
  echo "ERROR: Cannot find rpminspect in PATH." >&2
  exit 1
fi

# How many threads does the system have available to use
available_threads=$(grep -c processor /proc/cpuinfo)
if [[ -z "${available_threads}" ]]; then
  echo "ERROR: Unable to find number of system threads." >&2
  exit 1
fi

# Define the default value if unspecified or lower to max count if
# user has requested more threads than available
if [[ "${threads}" -eq 0 ]] || [[ "${threads}" -gt "${available_threads}" ]]; then
  threads="${available_threads}"
fi

# Make sure rpminspect is in out PATH
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
while [[ $(pgrep -c run_rpminspect.sh) -gt 0 ]]; do
  echo "$(date) - Waiting for our final jobs to finish"
  ps x | grep '[r]un_rpminspect.sh'
  sleep 5
done

# Print the completion before the auto re-run
echo "$(date) - Run completed."

# If all jobs are done and conditions are met, let's run our comparisons
if [[ ${auto_run_comp} == 'true' ]] && [[ -s ${comp_list} ]]; then
    ${0} -f ${comp_list} -p ${profile}
fi

# All done
exit 0
