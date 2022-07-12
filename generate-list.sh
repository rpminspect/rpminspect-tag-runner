#!/bin/bash
# Create list of NVRs to test

# This could be moved to stdout or a value passed as an argument
LIST='list.txt'

# These should be exported by tag_runner at runtime
if [[ -z "${KOJI_CMD}" ]]; then
  echo "ERROR: KOJI_CMD value from profile is missing." >&2
  exit 1
elif [[ -z "${KOJI_TAG}" ]]; then
  echo "ERROR: KOJI_TAG value from profile is missing." >&2
  exit 1
fi

# Required to properly catch KOJI_CMD failures
set -o pipefail

# Hide the ugly error messages from the user
# DeprecationWarning: The stub function for translation is no longer used
echo "$(date) - INFO: Generating ${LIST}"
${KOJI_CMD} list-tagged --inherit --latest ${KOJI_TAG} 2>/dev/null | tail -n +3 | awk '{print $1}' | sort > ${LIST}

# Check if KOJI_CMD is installed
ec="$?"
if [[ ${ec} -eq 127 ]]; then
  echo "ERROR: The requested program '${KOJI_CMD}' is not installed."
  exit 1
fi

# See if we had a clean error and a non-empty file
if [[ ${ec} -ne 0 ]]; then
  echo "ERROR: list generation koji call failed" >&2
  exit 1
elif [[ ! -s ${LIST} ]]; then
  echo "ERROR: requested tag appers to be empty." >&2
  exit 1
fi

echo "$(date) - INFO: ${LIST} generated successfully."
exit 0
