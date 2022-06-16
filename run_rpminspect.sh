#!/bin/bash
# Boot strap script to test a lot of builds against rpminspect
#
# Things we want:
# Easy to reproduce results
# Easy to modify params
# Catch related data per-build like:
#  log and stderr
#  How long it took to run
#  easy way to check success vs failure

# Support inspections or comparisons
BEFORE_BUILD="$1"
[[ -n "${BEFORE_BUILD}" ]] || exit 1
[[ -n "$2" ]] && AFTER_BUILD="$2"

# Options to run and where we save our run's logs
# TODO: Make this dynamic based on the tag used
CMD='rpminspect-centos'
LOG="logs/${BEFORE_BUILD}.log"
if [[ -n "${AFTER_BUILD}" ]]; then
    LOG="logs/${BEFORE_BUILD}-${AFTER_BUILD}-comparison.log"
fi
[[ -d logs ]] || mkdir logs
OPTS="-s VERIFY -w mytmp -o $LOG"

# Start the run and time it
FULL_CMD="$CMD $OPTS ${BEFORE_BUILD} ${AFTER_BUILD}"
echo "${FULL_CMD}" > ${LOG}.command
STARTTIME=$(date +'%s')
echo ${STARTTIME} > ${LOG}.starttime

# pipefail needed if we want to use tee and keep $?
set -o pipefail
${FULL_CMD} 2>${LOG}.stderr | tee ${LOG}.stdout

# empty success file if happy; exit code stored in file if needed
EC=$?
if [[ ${EC} -eq 0 ]]; then
    echo "${BEFORE_BUILD} ${AFTER_BUILD}" > ${LOG}.success
else
    echo ${EC} > ${LOG}.exitcode
fi

# Wrap up our runtime logging
ENDTIME=$(date +'%s')
echo ${ENDTIME} > ${LOG}.endtime
echo $((${ENDTIME} - ${STARTTIME})) > ${LOG}.runtime

# All done
exit $EC
