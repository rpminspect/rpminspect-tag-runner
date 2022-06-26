#!/bin/bash
# Create list of NVRs to test

# TODO: Make this dynamic between products
KOJI_CMD='koji -p stream'
KOJI_TAG='c9s-pending'
LIST='list.txt'

# Required to properly catch KOJI_CMD failures
set -o pipefail

# Hide the ugly error messages from the user
# DeprecationWarning: The stub function for translation is no longer used
echo "$(date) - INFO: Generating ${LIST}"
${KOJI_CMD} list-tagged --inherit --latest ${KOJI_TAG} 2>/dev/null | tail -n +3 | awk '{print $1}' > ${LIST}

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
