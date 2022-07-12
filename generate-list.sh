#!/bin/bash
# Create a list of NVRs to test tag_runner against

# Check for user specified options
while getopts "e:f:p:" arg; do
  case "${arg}" in
    # File with list of packages to exclude from our list
    e)
      EXCLUDES="${OPTARG}"
      ;;
    # File with our list of packages to test
    f)
      LIST="${OPTARG}"
      ;;
    # Profile to load in profiles/ 
    p)
      PROFILE="${OPTARG}"
      ;;
    *)
      echo "ERROR: Unknown argument: '${OPTARG}'" >&2
      exit 1
      ;;
  esac
done

shift "$(($OPTIND - 1))"

# Defaults to list.txt
[[ -z "${LIST}" ]] && LIST='list.txt'

# This is mostly used when debugging or testing as tag_runner exports
# the required values
if [[ -n "${PROFILE}" ]]; then
  source profiles/${PROFILE}.sh
  if [[ $? -ne 0 ]]; then
    echo "ERROR: Unable to load profile ${PROFILE}." >&2
    exit 1
  fi
fi

# These should be exported by tag_runner at runtime and can exist without
# a profile specified, but we check to avoid breaking the workflow
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
echo "$(date) - INFO: Generating ${LIST} for ${KOJI_TAG}"
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

echo "$(date) - INFO: Generated ${LIST} successfully for ${KOJI_TAG}"
exit 0
