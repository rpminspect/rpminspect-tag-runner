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
OP_MODE='inspection'
BEFORE_BUILD="$1"
AFTER_BUILD=''
[[ -n "${BEFORE_BUILD}" ]] || exit 1
[[ -n "$2" ]] && AFTER_BUILD="$2" && OP_MODE='comparison'

# Report success and failure in the root directory
PASS_LIST="pass-${OP_MODE}.txt"
FAIL_LIST="fail-${OP_MODE}.txt"

# tag_runner.sh should source and export from our profile
if [[ -z "$RPMINSPECT_CMD" ]]; then
    echo "ERROR: Required environment variable 'RPMINSPECT_CMD' missing." >&2
    exit 1
fi

# Options to run and where we save our run's logs
LOG="logs/${BEFORE_BUILD}.log"
if [[ -n "${AFTER_BUILD}" ]]; then
    LOG="logs/${BEFORE_BUILD}-${AFTER_BUILD}-comparison.log"
fi
[[ -d logs ]] || mkdir logs
OPTS="-s VERIFY -w mytmp -o $LOG"

# Start the run and time it
FULL_CMD="$RPMINSPECT_CMD $OPTS ${BEFORE_BUILD} ${AFTER_BUILD}"
echo "${FULL_CMD}" > ${LOG}.command
STARTTIME=$(date +'%s')
echo ${STARTTIME} > ${LOG}.starttime

# pipefail needed if we want to use tee and keep $?
set -o pipefail
${FULL_CMD} 2>${LOG}.stderr | tee ${LOG}.stdout

# Store NVR if success so you don't have to read filename if walking *success
# The exit code is stored in file if non-passing; we can use filename here instead
#
# The pass/fail list are nice to have a single report file but are a bit redundant
EC=$?
if [[ ${EC} -eq 0 ]]; then
    echo "${BEFORE_BUILD} ${AFTER_BUILD}" > ${LOG}.success
    echo "${BEFORE_BUILD} ${AFTER_BUILD}" >> ${PASS_LIST}
else
    echo ${EC} > ${LOG}.exitcode
    echo "${BEFORE_BUILD} ${AFTER_BUILD}" >> ${FAIL_LIST}
fi

# Wrap up our runtime logging
ENDTIME=$(date +'%s')
echo ${ENDTIME} > ${LOG}.endtime
echo $((${ENDTIME} - ${STARTTIME})) > ${LOG}.runtime

# If we in inspection OP_MODE then let's prepare for the comparison run
if [[ "${OP_MODE}" == 'inspection' ]]; then
    # Find package via NVR by polling koji API for the info
    # Failure handling and looping should be handled in the python script
    PACKAGE=$(./nvr-to-package.py ${BEFORE_BUILD})
    if [[ -z "${PACKAGE}" ]]; then
      echo "ERROR: Unable to find package name of ${BEFORE_BUILD}" >&2
      # Catch a list to look up if things broke upstream
      echo "$BEFORE_BUILD" >> nvr-to-package-failure.log
      exit $EC
    fi
    # Ask koji via cli for last 2 tagged builds for a package on the tag 
    OLD_BUILDS=$(${KOJI_CMD} list-tagged --latest-n 2 --inherit --quiet ${KOJI_TAG} ${PACKAGE} | awk '{print $1}')
    if [[ -z "${OLD_BUILDS}" ]]; then
      echo "$(date) - ERROR: KOJI_CMD to NVRs logic broke on ${PACKAGE} - please investigate." >&2
      echo "${PACKAGE}" >> comparison-generation-failure.log
      exit $EC
    fi
    # Now we need to find the previous build, if it exists, and add to our comp list
    # The order is not always correct so we need a loop here
    for OLD_BUILD in ${OLD_BUILDS}; do
      # The "before" build becomes the after if we find an older one.
      if [[ "${OLD_BUILD}" != "${BEFORE_BUILD}" ]]; then
        echo "${OLD_BUILD} ${BEFORE_BUILD}" >> comparison-list.txt
        OLD_BUILD_FOUND='true'
        break
      fi
    done
fi

# All done
exit $EC
