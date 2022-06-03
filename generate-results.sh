#!/bin/bash
# Used to generate a list of packages that have successfully run
# in comparison inspections
LOGS_DIR='logs'
LOGS_END='comparison.log.success'
RESULTS="results-$(date +%F).log"
ls ${LOGS_DIR}/*${LOGS_END} &>/dev/null
if [[ $? -ne 0 ]]; then
  echo "ERROR: No comparison logs found. Exiting." >&2
  exit 1
fi

# Results should have two NVRs from the comparison with a space separating them
for nvr in $(cat ${LOGS_DIR}/*${LOGS_END} | cut -d ' ' -f 2); do
  echo "$(date) - Working on $nvr"
  ./nvr-to-package.py ${nvr} >> ${RESULTS}
  # It may be worth putting this in a loop or add retry logic 
  if [[ $? -ne 0 ]]; then
    echo "ERROR: $nvr failed to resolve to a package name" >&2
  fi
done
